-- ─────────────────────────────────────────────────────────────
--  Neovim — agus-darmawan/dotfiles
--  Languages are registered in lua/config/languages.lua
-- ─────────────────────────────────────────────────────────────

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
require("util.ros").setup()

-- machine-local tweaks, not in git: lua/config/local.lua (see docs/CUSTOMIZE.md)
if (vim.uv or vim.loop).fs_stat(vim.fn.stdpath("config") .. "/lua/config/local.lua") then require("config.local") end
