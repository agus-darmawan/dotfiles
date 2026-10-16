-- ─────────────────────────────────────────────────────────────
--  Language registry — the ONE place to add/remove a language.
--
--  treesitter        parsers to install
--  servers()         LSP servers  (mason = false → use system binary)
--  formatters_by_ft  conform.nvim
--  formatters        formatter overrides / conditions
--  linters_by_ft     nvim-lint
--  mason_tools       extra CLI tools (formatters, linters, debug adapters)
--
--  Dart/Flutter is handled by flutter-tools.nvim (lua/plugins/flutter.lua).
-- ─────────────────────────────────────────────────────────────
local M = {}

local function has(bin)
  return vim.fn.executable(bin) == 1
end

-- formatter runs only when one of these config files exists upwards
local function needs_config(files)
  return function(_, ctx)
    return vim.fs.find(files, { upward = true, path = ctx.dirname })[1] ~= nil
  end
end

M.treesitter = {
  -- robotics / systems
  "c", "cpp", "cuda", "cmake", "make", "ninja", "python", "rust", "go", "gomod", "gosum",
  "xml", "yaml", "toml", "json", "proto",
  -- web
  "javascript", "typescript", "tsx", "html", "css", "scss", "graphql", "prisma", "svelte", "vue",
  -- mobile
  "dart", "swift", "kotlin",
  -- ops / shell
  "bash", "dockerfile", "sql", "nginx", "terraform", "hcl",
  -- editor / docs
  "lua", "luadoc", "vim", "vimdoc", "query", "regex", "markdown", "markdown_inline",
  "diff", "gitcommit", "git_rebase", "gitignore", "git_config", "comment",
}

function M.servers()
  return {
    -- C/C++ (ROS2): prefer system clangd (Xcode / apt), Mason otherwise
    clangd = {
      mason = not has("clangd"),
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
        "--query-driver=/usr/bin/**,/usr/local/bin/**,/opt/**",
        "-j=4",
      },
      root_markers = { "compile_commands.json", ".clangd", "compile_flags.txt", ".git" },
      init_options = { usePlaceholders = true, completeUnimported = true, clangdFileStatus = true },
    },

    neocmake = {},

    -- Python: types + ruff for lint/format
    basedpyright = {
      before_init = function(_, config)
        local extra = require("util.ros").python_paths(config.root_dir)
        if #extra > 0 then
          config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
            basedpyright = { analysis = { extraPaths = extra } },
          })
        end
      end,
      settings = {
        basedpyright = {
          analysis = {
            typeCheckingMode = "standard",
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
            diagnosticMode = "openFilesOnly",
          },
        },
      },
    },
    ruff = {
      on_attach = function(client)
        client.server_capabilities.hoverProvider = false -- leave hover to pyright
      end,
    },

    -- ROS launch xml / urdf / xacro / package.xml
    lemminx = {
      filetypes = { "xml", "xsd", "xsl", "xslt", "svg" },
      settings = {
        xml = {
          format = { enabled = true, splitAttributes = "preserve", maxLineWidth = 120 },
          validation = { noGrammar = "ignore" },
        },
      },
    },

    -- Web
    vtsls = {
      settings = {
        complete_function_calls = true,
        vtsls = { autoUseWorkspaceTsdk = true, experimental = { completion = { enableServerSideFuzzyMatch = true } } },
        typescript = {
          updateImportsOnFileMove = { enabled = "always" },
          inlayHints = {
            parameterNames = { enabled = "literals" },
            variableTypes = { enabled = false },
            functionLikeReturnTypes = { enabled = true },
          },
        },
      },
    },
    eslint = {},
    tailwindcss = {},
    cssls = {},
    html = {},
    emmet_language_server = {
      filetypes = { "html", "css", "javascriptreact", "typescriptreact", "svelte", "vue" },
    },

    -- Data / config
    jsonls = {
      before_init = function(_, config)
        config.settings.json.schemas = require("schemastore").json.schemas()
      end,
      settings = { json = { validate = { enable = true } } },
    },
    yamlls = {
      before_init = function(_, config)
        config.settings.yaml.schemas = require("schemastore").yaml.schemas()
      end,
      settings = {
        redhat = { telemetry = { enabled = false } },
        yaml = {
          keyOrdering = false,
          validate = true,
          schemaStore = { enable = false, url = "" },
        },
      },
    },
    taplo = {},

    -- Shell / containers
    bashls = { filetypes = { "sh", "bash", "zsh" } },
    dockerls = {},
    docker_compose_language_service = {},

    -- Lua (this config)
    lua_ls = {
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
          completion = { callSnippet = "Replace" },
          hint = { enable = true, arrayIndex = "Disable" },
          diagnostics = { globals = { "vim", "Snacks" } },
        },
      },
    },

    -- Other languages
    gopls = {
      settings = {
        gopls = {
          gofumpt = true,
          usePlaceholders = true,
          staticcheck = true,
          hints = { parameterNames = true, assignVariableTypes = true },
        },
      },
    },
    rust_analyzer = {
      settings = { ["rust-analyzer"] = { check = { command = "clippy" }, cargo = { allFeatures = true } } },
    },
    sourcekit = { mason = false, filetypes = { "swift", "objc", "objcpp" } },
    marksman = {},
  }
end

M.formatters_by_ft = {
  lua = { "stylua" },
  python = { "ruff_organize_imports", "ruff_format" },
  -- C/C++: only clang-format with a .clang-format file — never reformat foreign code
  c = { "clang_format", lsp_format = "never" },
  cpp = { "clang_format", lsp_format = "never" },
  cuda = { "clang_format", lsp_format = "never" },
  cmake = { "gersemi" },
  sh = { "shfmt" },
  bash = { "shfmt" },
  zsh = { "shfmt" },
  javascript = { "biome", "prettierd", stop_after_first = true },
  javascriptreact = { "biome", "prettierd", stop_after_first = true },
  typescript = { "biome", "prettierd", stop_after_first = true },
  typescriptreact = { "biome", "prettierd", stop_after_first = true },
  json = { "biome", "prettierd", stop_after_first = true },
  jsonc = { "biome", "prettierd", stop_after_first = true },
  css = { "prettierd" },
  scss = { "prettierd" },
  html = { "prettierd" },
  markdown = { "prettierd" },
  yaml = { "prettierd" },
  graphql = { "prettierd" },
  toml = { "taplo" },
  go = { "goimports", "gofumpt" },
  rust = { "rustfmt", lsp_format = "fallback" },
  swift = { "swiftformat" },
  dart = { "dart_format" },
  xml = { lsp_format = "prefer" },
  ["_"] = { "trim_whitespace" },
}

M.formatters = {
  clang_format = { condition = needs_config({ ".clang-format", "_clang-format" }) },
  biome = { condition = needs_config({ "biome.json", "biome.jsonc" }) },
  gersemi = { condition = needs_config({ ".gersemirc" }) },
  shfmt = { prepend_args = { "-i", "2", "-ci" } },
}

M.linters_by_ft = {
  dockerfile = { "hadolint" },
}

M.mason_tools = {
  -- formatters
  "stylua", "prettierd", "biome", "shfmt", "gersemi", "taplo", "goimports", "gofumpt",
  -- linters
  "hadolint", "shellcheck",
  -- debug adapters
  "codelldb", "debugpy",
}

-- clang-format only from Mason when the system has none
if not has("clang-format") then
  table.insert(M.mason_tools, "clang-format")
end

return M
