return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true }) end,
        mode = { "n", "x" },
        desc = "Format",
      },
    },
    opts = function()
      local langs = require("config.languages")
      return {
        formatters_by_ft = langs.formatters_by_ft,
        formatters = langs.formatters,
        default_format_opts = { lsp_format = "fallback", timeout_ms = 2000 },
        format_on_save = function(buf)
          if not vim.g.autoformat or vim.b[buf].autoformat == false then return end
          local name = vim.api.nvim_buf_get_name(buf)
          if name:match("/node_modules/") or name:match("/build/") or name:match("/install/") then return end
          return {}
        end,
      }
    end,
  },
}
