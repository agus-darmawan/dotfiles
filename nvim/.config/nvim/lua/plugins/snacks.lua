-- snacks.nvim: picker, explorer, terminal, lazygit, dashboard, notifier, toggles …
local function float_cmd(cmd)
  return function() Snacks.terminal(cmd, { win = { style = "float", width = 0.92, height = 0.92, border = "rounded" } }) end
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000, style = "compact" },
      indent = { enabled = true, animate = { enabled = false } },
      scope = { enabled = true },
      words = { enabled = true },
      statuscolumn = { enabled = true },
      scroll = { enabled = false },
      image = { enabled = true },
      lazygit = { configure = true },
      explorer = { enabled = true, replace_netrw = false },
      picker = {
        enabled = true,
        ui_select = true,
        layout = { preset = "telescope" },
        sources = {
          explorer = { layout = { layout = { position = "right" } }, hidden = true },
          files = { hidden = true },
          grep = { hidden = true },
        },
        exclude = { "node_modules", ".git", ".cache", "build", "install", "log", ".dart_tool" },
      },
      terminal = { win = { style = "terminal" } },
      dashboard = {
        enabled = true,
        preset = {
          header = table.concat({
            " █████╗  ██████╗ ██╗   ██╗███████╗",
            "██╔══██╗██╔════╝ ██║   ██║██╔════╝",
            "███████║██║  ███╗██║   ██║███████╗",
            "██╔══██║██║   ██║██║   ██║╚════██║",
            "██║  ██║╚██████╔╝╚██████╔╝███████║",
            "╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚══════╝",
            "  robotics · web · mobile · infra  ",
          }, "\n"),
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.smart()" },
            { icon = " ", key = "g", desc = "Grep", action = ":lua Snacks.picker.grep()" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
            { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰊢 ", key = "l", desc = "Lazygit", action = ":lua Snacks.lazygit()" },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })",
            },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
      styles = {
        terminal = { keys = { term_normal = { "<esc><esc>", function() vim.cmd("stopinsert") end, mode = "t" } } },
      },
    },
    keys = {
      -- find
      { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart find files" },
      { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command history" },
      { "<leader>e", function() Snacks.explorer() end, desc = "Explorer" },
      { "<leader>ff", function() Snacks.picker.files() end, desc = "Files" },
      { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Git files" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
      { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Config files" },
      { "<leader>fn", "<cmd>enew<cr>", desc = "New file" },
      -- search
      { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep" },
      { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Word / selection", mode = { "n", "x" } },
      { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer lines" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "Help" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sc", function() Snacks.picker.commands() end, desc = "Commands" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer diagnostics" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
      { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
      { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix" },
      { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo history" },
      { "<leader>sr", function() Snacks.picker.resume() end, desc = "Resume last picker" },
      { "<leader>st", function() Snacks.picker.todo_comments() end, desc = "TODOs" },
      { "<leader>sn", function() Snacks.picker.notifications() end, desc = "Notifications" },
      { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
      -- git
      { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
      { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit log" },
      { "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "Lazygit file history" },
      { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git status" },
      { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git branches" },
      { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Git log (line)" },
      { "<leader>go", function() Snacks.gitbrowse() end, desc = "Open in browser", mode = { "n", "x" } },
      -- terminal & tools
      { "<C-/>", function() Snacks.terminal() end, desc = "Terminal", mode = { "n", "t" } },
      { "<C-_>", function() Snacks.terminal() end, desc = "which_key_ignore", mode = { "n", "t" } },
      {
        "<leader>tt",
        function() Snacks.terminal(nil, { win = { style = "float", border = "rounded" } }) end,
        desc = "Float terminal",
      },
      {
        "<leader>tv",
        function() Snacks.terminal(nil, { win = { position = "right", width = 0.4 } }) end,
        desc = "Side terminal",
      },
      { "<leader>td", float_cmd("lazydocker"), desc = "Lazydocker" },
      { "<leader>tb", float_cmd("btop"), desc = "btop" },
      { "<leader>ty", float_cmd("yazi"), desc = "Yazi" },
      -- misc
      { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete buffer" },
      { "<leader>bD", function() Snacks.bufdelete.other() end, desc = "Delete other buffers" },
      { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename file" },
      { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification history" },
      { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss notifications" },
      { "<leader>z", function() Snacks.zen() end, desc = "Zen mode" },
      { "<leader>.", function() Snacks.scratch() end, desc = "Scratch buffer" },
      { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next reference", mode = { "n", "t" } },
      { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev reference", mode = { "n", "t" } },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          _G.dd = function(...) Snacks.debug.inspect(...) end
          vim.print = _G.dd

          Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
          Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
          Snacks.toggle.option("relativenumber", { name = "Relative number" }):map("<leader>uL")
          Snacks.toggle.line_number():map("<leader>ul")
          Snacks.toggle.diagnostics():map("<leader>ud")
          Snacks.toggle.inlay_hints():map("<leader>uh")
          Snacks.toggle.treesitter():map("<leader>uT")
          Snacks.toggle.indent():map("<leader>ug")
          Snacks.toggle.dim():map("<leader>uD")
          Snacks.toggle
            .new({
              id = "autoformat",
              name = "Format on save",
              get = function() return vim.g.autoformat end,
              set = function(state) vim.g.autoformat = state end,
            })
            :map("<leader>uf")
        end,
      })
    end,
  },
}
