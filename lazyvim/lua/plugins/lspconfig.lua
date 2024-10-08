return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- lua stuff
        "lua-language-server",
        "stylua",

        -- web dev stuff
        "css-lsp",
        "html-lsp",
        "typescript-language-server",
        "deno",

        -- python
        --- lsp
        "jedi-language-server",
        --- formatter
        "black",
        "isort",

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
        ["python"] = { "black", "isort" },
      },
    },
  },
}
