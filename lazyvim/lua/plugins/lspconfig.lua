return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- lua stuff
        "lua-language-server",
        "stylua",

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

        -- java
        "java-language-server",
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
        ["python"] = { "black", "isort" },
      },
    },
  },
}
