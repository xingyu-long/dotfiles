return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- lua stuff
        "lua-language-server",
        "stylua",

        -- python
        --- lsp
        "ty",
        --- formatter
        "ruff",

        -- c
        "clangd",

        -- golang
        "gopls",
        "gofumpt",
      },
    },
  },

  -- add more treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "html",
        "css",
        "javascript",
        "c",
        "cpp",
        "go",
        "java",
        "python",
        "markdown",
        "markdown_inline",
      },
    },
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      format_on_save = false,
      formatters_by_ft = {
        ["python"] = { "ruff_format", "ruff_fix" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ty = {
          settings = {
            ty = {
              completions = {
                autoImport = true,
              },
              -- Set to 'openFilesOnly' to only see diagnostics for files you are editing
              diagnosticMode = "openFilesOnly",
              inlayHints = {
                variableTypes = true,
                callArgumentNames = true,
              },
            },
          },
        },
      },
    },
  },
}
