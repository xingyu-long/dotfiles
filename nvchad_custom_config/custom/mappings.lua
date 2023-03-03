---@type MappingsConfig
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },

    -- window management
    ["<leader>sv"] = { "<C-w>v" }, -- split window vertically
    ["<leader>sh"] = { "<C-w>s" }, -- split window horizontally
    ["<leader>se"] = { "<C-w>=" }, -- make split windows equal width & height
    ["<leader>sx"] = { ":close<CR>" }, -- close current split window

    -- navigate buffers
    ["<S-l>"] = { ":bnext<CR>" }, -- move to next buffer
    ["<S-h>"] = { ":bprevious<CR>" }, -- back to the previous buffer 

  },

  v = {
    -- move code block left or right
    ["<"] = { "<gv" },
    [">"] = { ">gv" },
  },
}

-- more keybinds!

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
