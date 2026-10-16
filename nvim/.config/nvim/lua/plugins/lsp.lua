return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "rounded",
        icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
      },
    },
  },

  { "b0o/SchemaStore.nvim", version = false },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      local langs = require("config.languages")

      -- diagnostics look
      vim.diagnostic.config({
        severity_sort = true,
        underline = true,
        update_in_insert = false,
        virtual_text = { spacing = 2, source = "if_many", prefix = "●" },
        float = { border = "rounded", source = true },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      })

      -- shared capabilities (blink completion)
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- register every server from the registry
      local ensure, system = {}, {}
      for name, cfg in pairs(langs.servers()) do
        local use_mason = cfg.mason ~= false
        cfg.mason = nil
        vim.lsp.config(name, cfg)
        table.insert(use_mason and ensure or system, name)
      end

      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = vim.g.offline and {} or ensure,
        automatic_enable = ensure,
      })
      require("mason-tool-installer").setup({
        ensure_installed = langs.mason_tools,
        run_on_start = not vim.g.offline,
        start_delay = 3000,
      })

      -- system servers: enable only if the binary exists
      for _, name in ipairs(system) do
        local cmd = vim.lsp.config[name] and vim.lsp.config[name].cmd
        local bin = type(cmd) == "table" and cmd[1] or nil
        if bin and vim.fn.executable(bin) == 1 then vim.lsp.enable(name) end
      end

      -- buffer-local keymaps on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("dot_lsp_attach", { clear = true }),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end

          map("gd", function() Snacks.picker.lsp_definitions() end, "Goto definition")
          map("gD", function() Snacks.picker.lsp_declarations() end, "Goto declaration")
          map("gr", function() Snacks.picker.lsp_references() end, "References")
          map("gI", function() Snacks.picker.lsp_implementations() end, "Goto implementation")
          map("gy", function() Snacks.picker.lsp_type_definitions() end, "Goto type definition")
          map("K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Hover")
          map("gK", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, "Signature help")
          map("<C-k>", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, "Signature help", "i")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })
          map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>cl", "<cmd>checkhealth vim.lsp<cr>", "LSP info")
          map("<leader>ss", function() Snacks.picker.lsp_symbols() end, "Symbols (buffer)")
          map("<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, "Symbols (workspace)")

          if client and client.name == "clangd" then
            map("<leader>ch", "<cmd>LspClangdSwitchSourceHeader<cr>", "Switch header/source")
          end

          -- inline color swatches (tailwind, css, flutter) on Neovim 0.12+
          if client and vim.lsp.document_color and client:supports_method("textDocument/documentColor") then
            vim.lsp.document_color.enable(true, ev.buf)
          end

          if client and client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(false, { bufnr = ev.buf })
          end
        end,
      })
    end,
  },
}
