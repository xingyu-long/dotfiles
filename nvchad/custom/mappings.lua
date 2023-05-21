---@type MappingsTable
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },

    -- window management
    ["<leader>sv"] = { "<C-w>v" }, -- split window vertically
    ["<leader>sh"] = { "<C-w>s" }, -- split window horizontally
    ["<leader>se"] = { "<C-w>=" }, -- make split windows equal width & height
    ["<leader>sx"] = { ":close<CR>" }, -- close current split window

    ["<C-g>"] = { ":LazyGit<CR>" }, -- toggle lazygit
  },

  v = {
    -- move code block left or right
    ["<"] = { "<gv" },
    [">"] = { ">gv" },
  },
}

-- more keybinds!
M.tabufline = {
  plugin = true,

  n = {
    -- cycle through buffers
    ["<S-l>"] = {
      function()
        require("nvchad_ui.tabufline").tabuflineNext()
      end,
      "goto next buffer",
    },

    ["<S-h>"] = {
      function()
        require("nvchad_ui.tabufline").tabuflinePrev()
      end,
      "goto prev buffer",
    },

  },
}

M.telescope = {
  plugin = true,

  n = {
    -- find
    ["<leader>fs"] = { "<cmd> Telescope live_grep <CR>", "live grep" },

    -- git
    ["<leader>gc"] = { "<cmd> Telescope git_commits <CR>", "git commits" },
    ["<leader>gt"] = { "<cmd> Telescope git_status <CR>", "git status" },
    ["<leader>gb"] = { "<cmd> Telescope git_branches <CR>", "git branch" },
    ["<leader>gs"] = { "<cmd> Telescope git_status <CR>", "git status" },

  },
}

M.nvimtree = {
  plugin = true,

  n = {
    ["<leader>e"] = { ":NvimTreeToggle<CR>", "toggle file explorer" },
  },
}
return M
