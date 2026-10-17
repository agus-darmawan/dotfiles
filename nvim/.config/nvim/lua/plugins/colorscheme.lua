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
        flash = true,
        gitsigns = true,
        mason = true,
        mini = { enabled = true },
        native_lsp = { enabled = true, underlines = { errors = { "undercurl" }, warnings = { "undercurl" } } },
        snacks = { enabled = true },
        which_key = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
