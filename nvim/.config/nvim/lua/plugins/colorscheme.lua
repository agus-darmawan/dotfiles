return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      term_colors = true,
      dim_inactive = { enabled = false },
      float = { transparent = false, solid = false },
      styles = { comments = { "italic" }, keywords = { "italic" } },
      auto_integrations = true,
      integrations = {
        blink_cmp = true,
        dap = true,
        dap_ui = true,
        diffview = true,
        flash = true,
        gitsigns = true,
        grug_far = true,
        mason = true,
        mini = { enabled = true },
        native_lsp = { enabled = true, underlines = { errors = { "undercurl" }, warnings = { "undercurl" } } },
        snacks = { enabled = true },
        treesitter_context = true,
        which_key = true,
        lsp_trouble = true,
        render_markdown = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
