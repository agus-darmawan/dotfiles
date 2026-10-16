local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.showmode = false
opt.laststatus = 3
opt.cmdheight = 1
opt.pumheight = 12
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.linebreak = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " ", fold = " ", foldopen = "", foldclose = "", foldsep = " " }
opt.winborder = "rounded"
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"
opt.conceallevel = 2
opt.confirm = true
opt.mouse = "a"

-- Editing
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.shiftround = true
opt.virtualedit = "block"
opt.inccommand = "split"
opt.ignorecase = true
opt.smartcase = true
opt.completeopt = { "menu", "menuone", "noselect" }
opt.formatoptions = "jcroqlnt"

-- Files
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.autowrite = true
opt.updatetime = 200
opt.timeoutlen = 300

-- Folding (treesitter, all open by default)
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""

opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"
opt.spelllang = { "en" }
opt.shortmess:append({ W = true, I = true, c = true, C = true })

-- Clipboard: system clipboard locally, OSC52 over SSH / in containers.
-- OSC52 travels through tmux (set-clipboard on) and Ghostty to the Mac clipboard.
local function use_osc52()
  if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then return true end
  if vim.fn.has("mac") == 1 then return false end
  local has_native = vim.fn.executable("xclip") == 1
    or vim.fn.executable("xsel") == 1
    or vim.fn.executable("wl-copy") == 1
  return not (has_native and (vim.env.DISPLAY or vim.env.WAYLAND_DISPLAY))
end

if use_osc52() then
  local osc52 = require("vim.ui.clipboard.osc52")
  -- paste from the unnamed register: many terminals block OSC52 reads
  local function paste() return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") } end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end
vim.schedule(function() opt.clipboard = "unnamedplus" end)

-- Filetypes for robotics / containers
vim.filetype.add({
  extension = {
    urdf = "xml",
    xacro = "xml",
    sdf = "xml",
    world = "xml",
    launch = "xml",
    msg = "rosmsg",
    srv = "rosmsg",
    action = "rosmsg",
    idl = "idl",
    cu = "cuda",
    cuh = "cuda",
  },
  filename = {
    [".clangd"] = "yaml",
    ["colcon.meta"] = "json",
    [".clang-tidy"] = "yaml",
  },
  pattern = {
    [".*%.launch%.xml"] = "xml",
    [".*/docker%-compose[^/]*%.ya?ml"] = "yaml.docker-compose",
    [".*/compose[^/]*%.ya?ml"] = "yaml.docker-compose",
    ["Dockerfile[%.%-].*"] = "dockerfile",
    [".*%.Dockerfile"] = "dockerfile",
    [".*/%.github/workflows/.*%.ya?ml"] = "yaml.github",
    [".*%.env%..*"] = "sh",
  },
})

vim.g.autoformat = true

-- Offline mode (robots/Jetsons without internet): `export NVIM_OFFLINE=1`
-- skips automatic installs of parsers, LSP servers and tools, and plugin update checks.
vim.g.offline = vim.env.NVIM_OFFLINE == "1"
