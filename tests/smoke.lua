-- Headless Neovim smoke test.
--   NVIM_OFFLINE=1 nvim --headless "+lua dofile('tests/smoke.lua')"
-- Exits 0 when the config loads every plugin without errors, 1 otherwise.

local failures = {}
local function check(name, ok, detail)
  io.stdout:write(("  %s %s%s\n"):format(ok and "✓" or "✗", name, ok and "" or ("  — " .. tostring(detail))))
  if not ok then table.insert(failures, name) end
end

local function finish()
  io.stdout:write(#failures == 0 and "  neovim: all checks passed\n" or ("  neovim: %d failed\n"):format(#failures))
  vim.cmd(#failures == 0 and "qa!" or "cq 1")
end

-- hard timeout so CI never hangs
vim.defer_fn(function()
  io.stdout:write("  ✗ timeout\n")
  vim.cmd("cq 2")
end, 120000)

vim.defer_fn(function()
  local ok, err = pcall(function()
    -- a throwaway colcon workspace with one package
    local ws = vim.fn.tempname()
    vim.fn.mkdir(ws .. "/src/demo_pkg/src", "p")
    vim.fn.mkdir(ws .. "/build", "p")
    vim.fn.writefile(
      { "<package format='3'>", "  <name>demo_pkg</name>", "</package>" },
      ws .. "/src/demo_pkg/package.xml"
    )
    vim.fn.writefile({ "int main() { return 0; }" }, ws .. "/src/demo_pkg/src/main.cpp")
    vim.fn.writefile({ "string data", "---", "bool ok" }, ws .. "/src/demo_pkg/Ping.srv")

    vim.cmd.edit(ws .. "/src/demo_pkg/src/main.cpp")
    check("colorscheme", (vim.g.colors_name or ""):match("catppuccin") ~= nil, vim.g.colors_name)
    check("filetype cpp", vim.bo.filetype == "cpp", vim.bo.filetype)

    local ros = require("util.ros")
    check("ros package", ros.package() == "demo_pkg", ros.package())
    check("ros workspace", ros.workspace() == ws, ros.workspace())
    check("ros keymap", vim.fn.maparg("<leader>rb", "n") ~= "", "missing <leader>rb")

    for file, ft in pairs({
      ["robot.urdf"] = "xml",
      ["robot.xacro"] = "xml",
      ["bringup.launch.xml"] = "xml",
      ["Ping.srv"] = "rosmsg",
      ["docker-compose.yml"] = "yaml.docker-compose",
      ["Dockerfile.dev"] = "dockerfile",
    }) do
      local got = vim.filetype.match({ filename = file })
      check("filetype " .. file, got == ft, got)
    end

    local loaded, lerr = pcall(vim.cmd, "Lazy! load all")
    check("load all plugins", loaded, lerr)
    for _, mod in ipairs({
      "snacks",
      "blink.cmp",
      "conform",
      "lint",
      "dap",
      "dapui",
      "flutter-tools",
      "oil",
      "flash",
      "gitsigns",
      "lualine",
      "bufferline",
      "which-key",
      "trouble",
      "grug-far",
      "persistence",
      "render-markdown",
      "nvim-treesitter",
      "mason",
    }) do
      local rok, rerr = pcall(require, mod)
      check("require " .. mod, rok, rerr)
    end

    check("dap cpp configurations", #(require("dap").configurations.cpp or {}) >= 3)
    check("lsp config clangd", vim.lsp.config.clangd ~= nil and vim.lsp.config.clangd.cmd ~= nil)
    check("no startup errors", vim.v.errmsg == "", vim.v.errmsg)

    -- plugins report config problems as notifications (e.g. lualine after 2s)
    vim.wait(2500)
    local problems = {}
    for _, n in ipairs(Snacks.notifier.get_history()) do
      local level = type(n.level) == "number" and n.level or vim.log.levels[tostring(n.level):upper()] or 0
      if level >= vim.log.levels.WARN then table.insert(problems, n.msg) end
    end
    check("no warning notifications", #problems == 0, table.concat(problems, " | "))
  end)
  if not ok then check("smoke test crashed", false, err) end
  finish()
end, 3000)
