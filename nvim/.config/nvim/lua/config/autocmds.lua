local function augroup(name) return vim.api.nvim_create_augroup("dot_" .. name, { clear = true }) end
local au = vim.api.nvim_create_autocmd

-- highlight on yank
au("TextYankPost", {
  group = augroup("yank"),
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- reload files changed outside (colcon, git, codegen)
au({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then vim.cmd("checktime") end
  end,
})

-- equalize splits on resize
au("VimResized", {
  group = augroup("resize"),
  callback = function() vim.cmd("tabdo wincmd =") end,
})

-- restore cursor position
au("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(ev)
    local exclude = { gitcommit = true, gitrebase = true }
    if exclude[vim.bo[ev.buf].filetype] or vim.b[ev.buf].last_loc_done then return end
    vim.b[ev.buf].last_loc_done = true
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- close utility windows with q
au("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "help",
    "qf",
    "man",
    "lspinfo",
    "checkhealth",
    "notify",
    "startuptime",
    "gitsigns-blame",
  },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})

-- prose
au("FileType", {
  group = augroup("prose"),
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- per-language indentation (ROS C++ style = 2, Python = 4, Go = tabs)
au("FileType", {
  group = augroup("indent"),
  callback = function(ev)
    local four = { python = true, rust = true, swift = true, cs = true, php = true }
    local tabs = { go = true, make = true }
    local ft = vim.bo[ev.buf].filetype
    if four[ft] then
      vim.bo[ev.buf].shiftwidth, vim.bo[ev.buf].tabstop = 4, 4
    elseif tabs[ft] then
      vim.bo[ev.buf].expandtab = false
      vim.bo[ev.buf].shiftwidth, vim.bo[ev.buf].tabstop = 4, 4
    end
  end,
})

-- create parent dirs on save
au("BufWritePre", {
  group = augroup("mkdir"),
  callback = function(ev)
    if ev.match:match("^%w%w+:[\\/][\\/]") then return end
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- terminal buffers: no numbers, start in insert
au("TermOpen", {
  group = augroup("term"),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})
