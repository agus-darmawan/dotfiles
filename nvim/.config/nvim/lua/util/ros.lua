-- ─────────────────────────────────────────────────────────────
--  ROS 1 + ROS 2 helpers (active only where ROS is available:
--  dev containers and robots, never the Mac)
--
--  build the package you are editing → quickfix, compile_commands.json
--  for clangd, topic / node pickers, launch and run pickers.
--  ROS 2 uses colcon and ros2; ROS 1 uses catkin (catkin_tools or
--  catkin_make) and rostopic/rosnode/roslaunch/rosrun.
-- ─────────────────────────────────────────────────────────────
local M = {}

local uv = vim.uv or vim.loop
local exe = function(bin) return vim.fn.executable(bin) == 1 end

local function isdir(p)
  local st = uv.fs_stat(p)
  return st and st.type == "directory"
end

local function notify(msg, level, id)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "\u{f06a9} ROS", id = id })
end

local function start_path(buf)
  local name = vim.api.nvim_buf_get_name(buf or 0)
  if name ~= "" and not name:match("^%w+://") then return vim.fs.dirname(name) end
  return uv.cwd()
end

--- ROS sourced, or a build tool on PATH
function M.available() return vim.env.ROS_DISTRO ~= nil or exe("colcon") or exe("catkin") or exe("catkin_make") end

--- ROS 1 when the sourced distro says so, or only catkin is around
function M.ros1() return vim.env.ROS_VERSION == "1" or (vim.env.ROS_VERSION == nil and not exe("colcon")) end

--- nearest package.xml → name, dir
function M.package(path)
  local xml = vim.fs.find("package.xml", { upward = true, path = path or start_path() })[1]
  if not xml then return nil end
  local ok, lines = pcall(vim.fn.readfile, xml)
  if not ok then return nil end
  return table.concat(lines, "\n"):match("<name>%s*([^<%s]+)%s*</name>"), vim.fs.dirname(xml)
end

local markers = { "install", "build", "devel", ".catkin_tools", ".catkin_workspace" }

--- workspace root: a folder with src/ above the package (colcon or catkin)
function M.workspace(path)
  path = path or start_path()
  local _, pkgdir = M.package(path)
  local dirs = { pkgdir or path }
  for dir in vim.fs.parents(pkgdir or path) do
    table.insert(dirs, dir)
  end
  for _, dir in ipairs(dirs) do
    if isdir(dir .. "/src") and (not pkgdir or vim.startswith(pkgdir, dir .. "/src/")) then
      if pkgdir then return dir end
      for _, m in ipairs(markers) do
        if uv.fs_stat(dir .. "/" .. m) then return dir end
      end
    end
  end
end

--- python site-packages under install/ (for basedpyright extraPaths)
function M.python_paths(root)
  local ws = root and M.workspace(root) or M.workspace()
  if not ws then return {} end
  return vim.fn.glob(ws .. "/install/*/lib/python3*/site-packages", false, true)
end

--- build/*/compile_commands.json (+ catkin_make's build/compile_commands.json) → <ws>/compile_commands.json
function M.compile_db(ws, quiet)
  ws = ws or M.workspace()
  if not ws then return notify("Not inside a workspace", vim.log.levels.WARN) end
  local files = vim.fn.glob(ws .. "/build/*/compile_commands.json", false, true)
  vim.list_extend(files, vim.fn.glob(ws .. "/build/compile_commands.json", false, true))
  local all = {}
  for _, f in ipairs(files) do
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(f), "\n"))
    if ok and type(data) == "table" then vim.list_extend(all, data) end
  end
  if #all == 0 then return notify("No compile_commands.json under build/", vim.log.levels.WARN) end
  vim.fn.writefile({ vim.json.encode(all) }, ws .. "/compile_commands.json")
  if not quiet then notify(("compile_commands.json: %d entries"):format(#all)) end
  -- restart clangd so it reads the new database
  for _, c in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
    local bufs = vim.tbl_keys(c.attached_buffers or {})
    c:stop()
    vim.defer_fn(function()
      for _, b in ipairs(bufs) do
        if vim.api.nvim_buf_is_valid(b) then vim.api.nvim_exec_autocmds("FileType", { buffer = b }) end
      end
    end, 500)
  end
end

--- the build command for the workspace (colcon, catkin build or catkin_make)
local function build_cmd(ws, pkg)
  local cmake =
    { "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON", "-DCMAKE_BUILD_TYPE=" .. (vim.env.CMAKE_BUILD_TYPE or "RelWithDebInfo") }
  if not M.ros1() then
    local args = { "colcon", "build", "--symlink-install", "--event-handlers", "console_cohesion+" }
    if pkg then vim.list_extend(args, { "--packages-up-to", pkg }) end
    table.insert(args, "--cmake-args")
    return vim.list_extend(args, cmake)
  end
  if exe("catkin") and (isdir(ws .. "/.catkin_tools") or not isdir(ws .. "/devel")) then
    local args = { "catkin", "build", "--no-status" }
    if pkg then table.insert(args, pkg) end
    table.insert(args, "--cmake-args")
    return vim.list_extend(args, cmake)
  end
  local args = vim.list_extend({ "catkin_make" }, cmake)
  table.insert(args, "-DCATKIN_WHITELIST_PACKAGES=" .. (pkg or ""))
  return args
end

M.last_log = {}

--- build in the background → quickfix, compile_commands.json, clangd restart
function M.build(pkg)
  local ws = M.workspace()
  if not ws then return notify("Not inside a workspace", vim.log.levels.ERROR) end
  local args = build_cmd(ws, pkg)
  if not exe(args[1]) then
    return notify(args[1] .. " not found — start nvim from a shell where ROS is sourced", vim.log.levels.ERROR)
  end

  local what = pkg or "workspace"
  local started = uv.hrtime()
  notify(("\u{f051f} building %s…"):format(what), nil, "build")
  vim.cmd("silent! wall")

  vim.system(args, { cwd = ws, text = true }, function(res)
    vim.schedule(function()
      M.last_log = vim.split((res.stdout or "") .. "\n" .. (res.stderr or ""), "\n")
      -- build tools print compiler output twice (console + summary): keep unique entries
      local parsed = vim.fn.getqflist({
        lines = M.last_log,
        efm = table.concat({
          "%f:%l:%c: fatal %trror: %m",
          "%f:%l:%c: %trror: %m",
          "%f:%l:%c: %tarning: %m",
          "%f:%l: %trror: %m",
          "CMake Error at %f:%l %m",
          "%-G%.%#",
        }, ","),
      }).items
      local items, seen = {}, {}
      for _, it in ipairs(parsed) do
        local key = table.concat({ it.bufnr, it.lnum, it.col, it.type, it.text }, "|")
        if it.valid == 1 and not seen[key] then
          seen[key] = true
          table.insert(items, it)
        end
      end
      vim.fn.setqflist({}, " ", { title = table.concat(args, " "), items = items })

      local secs = (uv.hrtime() - started) / 1e9
      local errors = #vim.tbl_filter(function(i) return i.type == "e" end, items)
      if res.code == 0 then
        local warn = #items - errors
        local extra = warn > 0 and (" · %d warning%s"):format(warn, warn == 1 and "" or "s") or ""
        notify(("✓ %s built in %.1fs%s"):format(what, secs, extra), nil, "build")
        if #items == 0 then vim.cmd("cclose") end
        M.compile_db(ws, true)
      else
        notify(
          ("✗ %s: %d error%s (%.1fs)\n]q/[q jump · <leader>rL log"):format(
            what,
            errors,
            errors == 1 and "" or "s",
            secs
          ),
          vim.log.levels.ERROR,
          "build"
        )
        if #items > 0 then vim.cmd("botright copen 6") end
      end
    end)
  end)
end

function M.show_log()
  if #M.last_log == 0 then return notify("No build log yet") end
  vim.cmd("botright new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.last_log)
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].modifiable = "nofile", "wipe", false
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
end

-- terminal + pickers ------------------------------------------------------

local function overlay()
  local ws = M.workspace()
  for _, f in ipairs({ "/install/setup.bash", "/devel/setup.bash" }) do
    if ws and uv.fs_stat(ws .. f) then return ("source %s%s && "):format(ws, f) end
  end
  return ""
end

local function run_in_term(cmd)
  Snacks.terminal.open({ "bash", "-lc", overlay() .. cmd }, {
    cwd = M.workspace(),
    auto_close = false,
    win = { position = "bottom", height = 0.35, wo = { winbar = " \u{f06a9} " .. cmd } },
  })
end

local function pick(title, items, on_pick)
  if #items == 0 then return notify("Nothing found: " .. title, vim.log.levels.WARN) end
  vim.ui.select(items, { prompt = title }, function(choice)
    if choice then on_pick(choice) end
  end)
end

local function list(cmd)
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then return {} end
  return vim.tbl_filter(function(l) return l ~= "" end, vim.tbl_map(vim.trim, out))
end

function M.topics()
  local cli = M.ros1() and "rostopic" or "ros2 topic"
  pick("topics", list(cli .. " list"), function(t)
    vim.ui.select({ "echo", "hz", "info" }, { prompt = t }, function(action)
      if action then run_in_term(("%s %s %s"):format(cli, action, t)) end
    end)
  end)
end

function M.nodes()
  local cli = M.ros1() and "rosnode" or "ros2 node"
  pick("nodes", list(cli .. " list"), function(n) run_in_term(("%s info %s"):format(cli, n)) end)
end

function M.launch()
  local pkg, dir = M.package()
  local root = dir or M.workspace()
  if not root then return notify("No package or workspace here", vim.log.levels.WARN) end
  local files = vim.fs.find(
    function(name)
      return name:match("%.launch%.py$")
        or name:match("%.launch%.xml$")
        or name:match("%.launch%.ya?ml$")
        or name:match("_launch%.py$")
        or name:match("%.launch$")
    end,
    { path = dir and root or (root .. "/src"), type = "file", limit = 200 }
  )
  pick("launch", files, function(f)
    local fpkg = M.package(vim.fs.dirname(f)) or pkg
    local cli = M.ros1() and "roslaunch" or "ros2 launch"
    run_in_term(("%s %s %s %s"):format(cli, fpkg, vim.fs.basename(f), vim.fn.input("args: ")))
  end)
end

function M.run()
  local ws = M.workspace()
  if not ws then return end
  local exes = {}
  for _, f in ipairs(vim.fn.glob(ws .. "/{install/*/lib,devel/lib}/*/*", false, true)) do
    if vim.fn.executable(f) == 1 and not f:match("%.so") then
      local p, e = f:match("/lib/([^/]+)/([^/]+)$")
      table.insert(exes, p .. " " .. e)
    end
  end
  pick("run", exes, function(choice) run_in_term((M.ros1() and "rosrun " or "ros2 run ") .. choice) end)
end

-- setup -----------------------------------------------------------------

function M.setup()
  -- package name per buffer for the statusline (cheap, also used outside ROS machines)
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    group = vim.api.nvim_create_augroup("dot_ros_pkg", { clear = true }),
    callback = function(ev)
      if vim.bo[ev.buf].buftype ~= "" or vim.b[ev.buf].ros_pkg_checked then return end
      vim.b[ev.buf].ros_pkg_checked = true
      if M.available() then vim.b[ev.buf].ros_pkg = M.package(start_path(ev.buf)) end
    end,
  })

  if not M.available() then return end -- the Mac: no ROS menu

  local cmd = vim.api.nvim_create_user_command
  cmd("RosBuild", function(o) M.build(o.args ~= "" and o.args or nil) end, { nargs = "?" })
  cmd("RosLog", M.show_log, {})
  cmd("RosCompileDb", function() M.compile_db() end, {})

  local function map(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { desc = desc }) end
  map("<leader>rb", function()
    local p = M.package()
    if not p then return notify("No package.xml above this file", vim.log.levels.WARN) end
    M.build(p)
  end, "Build this package")
  map("<leader>rB", function() M.build() end, "Build workspace")
  map("<leader>rL", M.show_log, "Last build log")
  map("<leader>rc", function() M.compile_db() end, "Merge compile_commands.json")
  map("<leader>rt", M.topics, "Topics")
  map("<leader>rn", M.nodes, "Nodes")
  map("<leader>rl", M.launch, "Launch file")
  map("<leader>rr", M.run, "Run executable")
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({ { "<leader>r", group = M.ros1() and "ros 1" or "ros 2", icon = { icon = "\u{f06a9}", color = "cyan" } } })
  end
end

return M
