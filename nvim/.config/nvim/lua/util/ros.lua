-- ─────────────────────────────────────────────────────────────
--  ROS 2 helpers: workspace/package detection, colcon build → quickfix,
--  compile_commands merge for clangd, topic/node/service pickers,
--  launch & run pickers, interface lookup.
-- ─────────────────────────────────────────────────────────────
local M = {}

local uv = vim.uv or vim.loop

local function isdir(p)
  local st = uv.fs_stat(p)
  return st and st.type == "directory"
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "󰚩 ROS2" })
end

local function start_path(buf)
  local name = vim.api.nvim_buf_get_name(buf or 0)
  if name ~= "" and not name:match("^%w+://") then
    return vim.fs.dirname(name)
  end
  return uv.cwd()
end

--- nearest package.xml → name, dir
function M.package(path)
  path = path or start_path()
  local xml = vim.fs.find("package.xml", { upward = true, path = path })[1]
  if not xml then
    return nil
  end
  local ok, lines = pcall(vim.fn.readfile, xml)
  if not ok then
    return nil
  end
  local name = table.concat(lines, "\n"):match("<name>%s*([^<%s]+)%s*</name>")
  return name, vim.fs.dirname(xml)
end

--- colcon workspace root (dir whose src/ contains the package)
function M.workspace(path)
  path = path or start_path()
  local _, pkgdir = M.package(path)
  local start = pkgdir or path
  local candidates = { start }
  for dir in vim.fs.parents(start) do
    table.insert(candidates, dir)
  end
  for _, dir in ipairs(candidates) do
    if isdir(dir .. "/src") then
      if not pkgdir or vim.startswith(pkgdir, dir .. "/src/") then
        if pkgdir or isdir(dir .. "/install") or isdir(dir .. "/build") then
          return dir
        end
      end
    end
  end
  -- fallback: cwd looks like a workspace
  local cwd = uv.cwd()
  if isdir(cwd .. "/src") and (isdir(cwd .. "/install") or isdir(cwd .. "/build")) then
    return cwd
  end
end

--- python site-packages inside install/ (for basedpyright extraPaths)
function M.python_paths(root)
  local ws = root and M.workspace(root) or M.workspace()
  if not ws then
    return {}
  end
  return vim.fn.glob(ws .. "/install/*/lib/python3*/site-packages", false, true)
end

--- every executable under install/<pkg>/lib/<pkg>/
function M.executables()
  local ws = M.workspace()
  if not ws then
    return {}
  end
  local out = {}
  for _, f in ipairs(vim.fn.glob(ws .. "/install/*/lib/*/*", false, true)) do
    if vim.fn.executable(f) == 1 and not f:match("%.py$") and not f:match("%.so") then
      table.insert(out, f)
    end
  end
  return out
end

--- merge build/*/compile_commands.json → <ws>/compile_commands.json
function M.compile_db(ws, quiet)
  ws = ws or M.workspace()
  if not ws then
    return notify("Not inside a colcon workspace", vim.log.levels.WARN)
  end
  local all, n = {}, 0
  for _, f in ipairs(vim.fn.glob(ws .. "/build/*/compile_commands.json", false, true)) do
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(f), "\n"))
    if ok and type(data) == "table" then
      vim.list_extend(all, data)
      n = n + 1
    end
  end
  if n == 0 then
    return notify("No compile_commands.json in build/ — build with -DCMAKE_EXPORT_COMPILE_COMMANDS=ON", vim.log.levels.WARN)
  end
  vim.fn.writefile({ vim.json.encode(all) }, ws .. "/compile_commands.json")
  if not quiet then
    notify(("compile_commands.json: %d packages, %d entries"):format(n, #all))
  end
  -- restart clangd so it picks up the new database
  for _, c in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
    local bufs = vim.tbl_keys(c.attached_buffers or {})
    c:stop()
    vim.defer_fn(function()
      for _, b in ipairs(bufs) do
        if vim.api.nvim_buf_is_valid(b) then
          vim.api.nvim_exec_autocmds("FileType", { buffer = b })
        end
      end
    end, 500)
  end
end

M.last_log = {}

--- colcon build/test in the background → quickfix
---@param opts {pkg?:string, upto?:boolean, test?:boolean}
function M.colcon(opts)
  opts = opts or {}
  local ws = M.workspace()
  if not ws then
    return notify("Not inside a colcon workspace", vim.log.levels.ERROR)
  end
  if vim.fn.executable("colcon") == 0 then
    return notify("colcon not found — source ROS first (`ros` in the shell)", vim.log.levels.ERROR)
  end

  local verb = opts.test and "test" or "build"
  local args = { "colcon", verb, "--event-handlers", "console_cohesion+" }
  if opts.pkg then
    vim.list_extend(args, { opts.upto and "--packages-up-to" or "--packages-select", opts.pkg })
  end
  if not opts.test then
    table.insert(args, 3, "--symlink-install")
    vim.list_extend(args, {
      "--cmake-args",
      "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
      "-DCMAKE_BUILD_TYPE=" .. (vim.env.CMAKE_BUILD_TYPE or "RelWithDebInfo"),
    })
  end

  local label = ("colcon %s %s"):format(verb, opts.pkg or "(all)")
  local started = uv.hrtime()
  notify("⏳ " .. label)
  vim.cmd("silent! wall")

  vim.system(args, { cwd = ws, text = true }, function(res)
    vim.schedule(function()
      local out = (res.stdout or "") .. "\n" .. (res.stderr or "")
      M.last_log = vim.split(out, "\n")
      vim.fn.setqflist({}, " ", {
        title = label,
        lines = M.last_log,
        efm = table.concat({
          "%f:%l:%c: fatal %trror: %m",
          "%f:%l:%c: %trror: %m",
          "%f:%l:%c: %tarning: %m",
          "%f:%l: %trror: %m",
          "CMake Error at %f:%l %m",
          "%-G%.%#",
        }, ","),
      })
      local secs = (uv.hrtime() - started) / 1e9
      local errors = #vim.tbl_filter(function(i)
        return i.valid == 1 and i.type == "e"
      end, vim.fn.getqflist())
      if res.code == 0 then
        notify(("✓ %s  (%.1fs)"):format(label, secs))
        if not opts.test then
          M.compile_db(ws, true)
        end
      else
        notify(("✗ %s failed — %d errors  (%.1fs)\n<leader>rL for full log"):format(label, errors, secs), vim.log.levels.ERROR)
        if #vim.fn.getqflist() > 0 then
          vim.cmd("botright copen")
        end
      end
    end)
  end)
end

function M.show_log()
  if #M.last_log == 0 then
    return notify("No colcon log yet")
  end
  vim.cmd("botright new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.last_log)
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].modifiable = "nofile", "wipe", false
  vim.bo[buf].filetype = "log"
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
end

-- terminal helpers -------------------------------------------------------

local function source_prefix()
  local ws = M.workspace()
  if ws and uv.fs_stat(ws .. "/install/setup.bash") then
    return ("source %s/install/setup.bash && "):format(ws)
  end
  return ""
end

local function run_in_term(cmd)
  local full = source_prefix() .. cmd
  Snacks.terminal.open({ "bash", "-lc", full }, {
    cwd = M.workspace(),
    auto_close = false,
    win = { position = "bottom", height = 0.35, wo = { winbar = " 󰚩 " .. cmd } },
  })
end
M.run_in_term = run_in_term

local function need_ros2()
  if vim.fn.executable("ros2") == 0 then
    notify("ros2 not found — start nvim from a sourced shell", vim.log.levels.ERROR)
    return false
  end
  return true
end

local function pick_list(title, cmd, on_pick)
  if not need_ros2() then
    return
  end
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return notify(table.concat(out, "\n"), vim.log.levels.ERROR)
  end
  local items = {}
  for _, line in ipairs(out) do
    line = vim.trim(line)
    if line ~= "" then
      table.insert(items, { text = line, value = line:match("^(%S+)") })
    end
  end
  if #items == 0 then
    return notify("Nothing found for: " .. cmd, vim.log.levels.WARN)
  end
  Snacks.picker({
    title = title,
    items = items,
    format = "text",
    layout = { preset = "select" },
    confirm = function(picker, item)
      picker:close()
      if item then
        on_pick(item.value)
      end
    end,
  })
end

local function choose_action(value, actions)
  local names = vim.tbl_map(function(a) return a[1] end, actions)
  vim.ui.select(names, { prompt = value }, function(_, idx)
    if idx then
      run_in_term(actions[idx][2]:format(value))
    end
  end)
end

function M.topics()
  pick_list("ROS2 topics", "ros2 topic list -t", function(t)
    choose_action(t, {
      { "echo", "ros2 topic echo %s" },
      { "echo --once", "ros2 topic echo --once %s" },
      { "hz", "ros2 topic hz %s" },
      { "bw", "ros2 topic bw %s" },
      { "info -v", "ros2 topic info -v %s" },
    })
  end)
end

function M.nodes()
  pick_list("ROS2 nodes", "ros2 node list", function(n)
    choose_action(n, {
      { "info", "ros2 node info %s" },
      { "params", "ros2 param dump %s" },
    })
  end)
end

function M.services()
  pick_list("ROS2 services", "ros2 service list -t", function(s)
    choose_action(s, {
      { "type", "ros2 service type %s" },
      { "interface", "ros2 interface show $(ros2 service type %s)" },
    })
  end)
end

function M.interfaces()
  pick_list("ROS2 interfaces", "ros2 interface list", function(i)
    if i:find("/") then
      run_in_term("ros2 interface show " .. i)
    end
  end)
end

--- `ros2 interface show` for the type under cursor (std_msgs::msg::String, std_msgs/msg/String, …)
function M.interface_under_cursor()
  local word = vim.fn.expand("<cWORD>"):gsub("[;,<>()&*]", "")
  word = word:gsub("::", "/"):gsub("%.", "/")
  if not word:find("/") then
    return M.interfaces()
  end
  run_in_term("ros2 interface show " .. word)
end

function M.launch()
  local pkg, dir = M.package()
  local root = dir or M.workspace()
  if not root then
    return notify("No package / workspace found", vim.log.levels.WARN)
  end
  local files = vim.fs.find(function(name)
    return name:match("%.launch%.py$") or name:match("%.launch%.xml$") or name:match("%.launch%.ya?ml$")
      or name:match("_launch%.py$")
  end, { path = root .. (dir and "" or "/src"), type = "file", limit = 200 })
  if #files == 0 then
    return notify("No launch files under " .. root, vim.log.levels.WARN)
  end
  vim.ui.select(files, {
    prompt = "ros2 launch",
    format_item = function(f) return f:sub(#root + 2) end,
  }, function(f)
    if not f then
      return
    end
    local fpkg = M.package(vim.fs.dirname(f)) or pkg
    local extra = vim.fn.input("launch args: ")
    run_in_term(("ros2 launch %s %s %s"):format(fpkg, vim.fs.basename(f), extra))
  end)
end

function M.run()
  local exes = M.executables()
  if #exes == 0 then
    return notify("No executables in install/ — build first", vim.log.levels.WARN)
  end
  vim.ui.select(exes, {
    prompt = "ros2 run",
    format_item = function(f)
      local p, e = f:match("/lib/([^/]+)/([^/]+)$")
      return ("%s  %s"):format(p, e)
    end,
  }, function(f)
    if f then
      local p, e = f:match("/lib/([^/]+)/([^/]+)$")
      run_in_term(("ros2 run %s %s"):format(p, e))
    end
  end)
end

-- setup -----------------------------------------------------------------

function M.setup()
  local cmd = vim.api.nvim_create_user_command
  local function cur_pkg()
    return (M.package())
  end

  cmd("Colcon", function(o)
    M.colcon({ pkg = o.args ~= "" and o.args or nil })
  end, { nargs = "?", desc = "colcon build [pkg]" })
  cmd("ColconTest", function(o)
    M.colcon({ test = true, pkg = o.args ~= "" and o.args or cur_pkg() })
  end, { nargs = "?" })
  cmd("ColconLog", M.show_log, {})
  cmd("RosCompileDb", function() M.compile_db() end, {})
  cmd("RosTopics", M.topics, {})
  cmd("RosNodes", M.nodes, {})
  cmd("RosServices", M.services, {})
  cmd("RosInterface", M.interface_under_cursor, {})
  cmd("RosLaunch", M.launch, {})
  cmd("RosRun", M.run, {})

  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { desc = desc })
  end
  map("<leader>rb", function()
    local p = cur_pkg()
    if not p then
      return notify("No package.xml above this file", vim.log.levels.WARN)
    end
    M.colcon({ pkg = p })
  end, "Build this package")
  map("<leader>ru", function() M.colcon({ pkg = cur_pkg(), upto = true }) end, "Build up-to this package")
  map("<leader>rB", function() M.colcon({}) end, "Build workspace")
  map("<leader>rT", function() M.colcon({ test = true, pkg = cur_pkg() }) end, "Test this package")
  map("<leader>rL", M.show_log, "Last colcon log")
  map("<leader>rc", function() M.compile_db() end, "Merge compile_commands.json")
  map("<leader>rt", M.topics, "Topics")
  map("<leader>rn", M.nodes, "Nodes")
  map("<leader>rs", M.services, "Services")
  map("<leader>ri", M.interface_under_cursor, "Interface under cursor")
  map("<leader>rI", M.interfaces, "All interfaces")
  map("<leader>rl", M.launch, "Launch file")
  map("<leader>rr", M.run, "Run executable")
  map("<leader>rp", function()
    local name, dir = M.package()
    local ws = M.workspace()
    notify(("package: %s\ndir: %s\nworkspace: %s\ndistro: %s  domain: %s"):format(
      name or "-", dir or "-", ws or "-", vim.env.ROS_DISTRO or "-", vim.env.ROS_DOMAIN_ID or "0"))
  end, "Package info")

  -- cache package name per buffer (statusline)
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    group = vim.api.nvim_create_augroup("dot_ros_pkg", { clear = true }),
    callback = function(ev)
      if vim.bo[ev.buf].buftype ~= "" or vim.b[ev.buf].ros_pkg_checked then
        return
      end
      vim.b[ev.buf].ros_pkg_checked = true
      local name = M.package(start_path(ev.buf))
      vim.b[ev.buf].ros_pkg = name
    end,
  })
end

return M
