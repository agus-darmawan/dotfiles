-- ROS 2 integration test: build a real ament package from Neovim and check clangd's database.
--   WS=<colcon ws> NVIM_OFFLINE=1 nvim --headless "+lua dofile('tests/ros.lua')"

local ws = assert(vim.env.WS, "set WS to a colcon workspace")
local failures = 0
local function check(name, ok, detail)
  io.stdout:write(("  %s %s%s\n"):format(ok and "✓" or "✗", name, ok and "" or ("  — " .. tostring(detail))))
  if not ok then failures = failures + 1 end
end

vim.defer_fn(function()
  io.stdout:write("  ✗ timeout\n")
  vim.cmd("cq 2")
end, 600000)

vim.defer_fn(function()
  local ros = require("util.ros")
  local src = vim.fn.glob(ws .. "/src/*/src/*.cpp", false, true)[1]
  check("package source found", src ~= nil, ws)
  vim.cmd.edit(src)

  local pkg = ros.package()
  check("package detected", pkg ~= nil, pkg)
  local function real(p) return p and (vim.uv or vim.loop).fs_realpath(p) or p end
  check("workspace detected", real(ros.workspace()) == real(ws), ros.workspace())

  local db = ws .. "/compile_commands.json"
  ros.colcon({ pkg = pkg })
  local built = vim.wait(540000, function() return (vim.uv or vim.loop).fs_stat(db) ~= nil end, 500)
  check("colcon build + compile_commands.json", built, table.concat(ros.last_log or {}, "\n"))

  if built then
    local entries = vim.json.decode(table.concat(vim.fn.readfile(db), "\n"))
    check("database has entries", #entries > 0, #entries)
  end

  vim.cmd(failures == 0 and "qa!" or "cq 1")
end, 2000)
