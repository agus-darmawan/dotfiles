-- nvim-treesitter `main` branch (requires the tree-sitter CLI + a C compiler)
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({})

      -- install missing parsers (async, no-op when present)
      local wanted = require("config.languages").treesitter
      local installed = {}
      for _, p in ipairs(ts.get_installed()) do
        installed[p] = true
      end
      local missing = vim.tbl_filter(function(p)
        return not installed[p]
      end, wanted)
      if #missing > 0 then
        ts.install(missing)
      end

      -- compound filetypes → parser
      vim.treesitter.language.register("yaml", { "yaml.docker-compose", "yaml.github" })
      vim.treesitter.language.register("bash", { "zsh", "sh" })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("dot_treesitter", { clear = true }),
        callback = function(ev)
          if not pcall(vim.treesitter.start, ev.buf) then
            return
          end
          local no_ts_indent = { python = true, yaml = true, markdown = true }
          if not no_ts_indent[vim.bo[ev.buf].filetype] then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = { max_lines = 3, multiline_threshold = 1, mode = "cursor" },
    keys = {
      {
        "[c",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Goto context",
      },
    },
  },
}
