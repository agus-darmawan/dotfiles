return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true })
        end,
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
          if not vim.g.autoformat or vim.b[buf].autoformat == false then
            return
          end
          local name = vim.api.nvim_buf_get_name(buf)
          if name:match("/node_modules/") or name:match("/build/") or name:match("/install/") then
            return
          end
          return {}
        end,
      }
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = require("config.languages").linters_by_ft
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("dot_lint", { clear = true }),
        callback = function()
          lint.try_lint(nil, { ignore_errors = true })
        end,
      })
    end,
  },
}
