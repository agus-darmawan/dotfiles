-- Debugging: C++ (codelldb) incl. ROS2 nodes from install/, Python (debugpy)
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: continue" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Debug: step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      {
        "<leader>dB",
        function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end,
        desc = "Conditional breakpoint",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue / start" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "REPL" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "x" } },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      local mason = vim.fn.stdpath("data") .. "/mason/packages"

      dapui.setup()
      require("nvim-dap-virtual-text").setup({ virt_text_pos = "eol" })
      dap.listeners.after.event_initialized.dapui = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui = function() dapui.close() end
      dap.listeners.before.event_exited.dapui = function() dapui.close() end

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })

      -- C / C++ / Rust
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = { command = mason .. "/codelldb/extension/adapter/codelldb", args = { "--port", "${port}" } },
      }

      local function pick(items, prompt)
        return coroutine.create(function(co)
          if #items == 0 then
            vim.notify("Nothing found — build with RelWithDebInfo first (cb / <leader>rb)", vim.log.levels.WARN)
            return coroutine.resume(co, dap.ABORT)
          end
          vim.ui.select(items, { prompt = prompt }, function(choice) coroutine.resume(co, choice or dap.ABORT) end)
        end)
      end

      local cpp = {
        {
          name = "ROS2: launch node from install/",
          type = "codelldb",
          request = "launch",
          program = function() return pick(require("util.ros").executables(), "ROS2 executable") end,
          args = function()
            local a = vim.fn.input("Args (e.g. --ros-args -p rate:=10): ")
            return vim.split(a, " ", { trimempty = true })
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
        {
          name = "Launch executable (path)",
          type = "codelldb",
          request = "launch",
          program = function() return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file") end,
          cwd = "${workspaceFolder}",
        },
        {
          name = "Attach to process",
          type = "codelldb",
          request = "attach",
          pid = require("dap.utils").pick_process,
        },
      }
      dap.configurations.cpp = cpp
      dap.configurations.c = cpp
      dap.configurations.rust = cpp

      -- Python (rclpy nodes, scripts)
      local py = mason .. "/debugpy/venv/bin/python"
      if vim.fn.executable(py) == 1 then
        require("dap-python").setup(py)
      else
        require("dap-python").setup("python3")
      end
    end,
  },
}
