---@type MappingsConfig
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
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

return M
