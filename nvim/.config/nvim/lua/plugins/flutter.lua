-- Flutter / Dart: LSP, run, hot reload, devices, DAP
return {
  {
    "nvim-flutter/flutter-tools.nvim",
    ft = "dart",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>Fr", "<cmd>FlutterRun<cr>", desc = "Run" },
      { "<leader>Fq", "<cmd>FlutterQuit<cr>", desc = "Quit" },
      { "<leader>Fh", "<cmd>FlutterReload<cr>", desc = "Hot reload" },
      { "<leader>FR", "<cmd>FlutterRestart<cr>", desc = "Hot restart" },
      { "<leader>Fd", "<cmd>FlutterDevices<cr>", desc = "Devices" },
      { "<leader>Fe", "<cmd>FlutterEmulators<cr>", desc = "Emulators" },
      { "<leader>Fo", "<cmd>FlutterOutlineToggle<cr>", desc = "Widget outline" },
      { "<leader>Fl", "<cmd>FlutterLogToggle<cr>", desc = "Dev log" },
      { "<leader>Fc", "<cmd>FlutterLogClear<cr>", desc = "Clear log" },
      { "<leader>Fp", "<cmd>FlutterPubGet<cr>", desc = "pub get" },
      { "<leader>Fs", "<cmd>FlutterLspRestart<cr>", desc = "Restart LSP" },
    },
    config = function()
      require("flutter-tools").setup({
        ui = { border = "rounded" },
        decorations = { statusline = { app_version = true, device = true } },
        widget_guides = { enabled = true },
        closing_tags = { enabled = true, prefix = "→ " },
        dev_log = { enabled = true, open_cmd = "botright 12split" },
        debugger = { enabled = true },
        lsp = {
          capabilities = require("blink.cmp").get_lsp_capabilities(),
          color = { enabled = true },
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            renameFilesWithClasses = "prompt",
            updateImportsOnRename = true,
            enableSnippets = true,
          },
        },
      })
    end,
  },
}
