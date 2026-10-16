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
