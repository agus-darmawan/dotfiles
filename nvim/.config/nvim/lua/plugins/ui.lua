return {
  {
    "nvim-mini/mini.icons",
    lazy = true,
    opts = {},
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },

  -- statusline (bottom) — tmux owns the top bar
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      local function lsp_names()
        local names = {}
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
          table.insert(names, c.name)
        end
        return #names > 0 and (" " .. table.concat(names, " ")) or ""
      end
      local function ros_pkg()
        local pkg = vim.b.ros_pkg
        return pkg and ("󰚩 " .. pkg) or ""
      end
      -- hide the extras when nvim sits in a narrow tmux split
      local function wide() return vim.o.columns > 90 end
      local function autoformat() return vim.g.autoformat and "" or "󰉥 off" end

      return {
        options = {
          theme = pcall(require, "lualine.themes.catppuccin-mocha") and "catppuccin-mocha" or "catppuccin",
          globalstatus = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = { statusline = { "snacks_dashboard" } },
        },
        sections = {
          lualine_a = { { "mode", fmt = function(s) return s:sub(1, 3) end } },
          lualine_b = { "branch", { "diff", symbols = { added = " ", modified = " ", removed = " " } } },
          lualine_c = {
            { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { "filename", path = 1, symbols = { modified = " ●", readonly = " 󰌾" } },
          },
          lualine_x = {
            { ros_pkg, cond = wide, color = { fg = "#94e2d5" } },
            { autoformat, color = { fg = "#f38ba8" } },
            { lsp_names, cond = wide, color = { fg = "#89b4fa" } },
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        extensions = { "lazy", "mason", "quickfix", "man" },
      }
    end,
  },

  -- buffer tabs

  -- keymap hints
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 300,
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "git" },
        { "<leader>gh", group = "hunks" },
        { "<leader>r", group = "ros2", icon = { icon = "󰚩", color = "cyan" } },
        { "<leader>s", group = "search" },
        { "<leader>t", group = "terminal/tools" },
        { "<leader>u", group = "ui toggles" },
        { "<leader>w", group = "window" },
        { "<leader>x", group = "diagnostics/quickfix" },
        { "<leader><tab>", group = "tabs" },
        { "[", group = "prev" },
        { "]", group = "next" },
        { "g", group = "goto" },
        { "gs", group = "surround" },
      },
    },
    keys = {
      { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
    },
  },

  -- markdown rendering in-buffer
}
