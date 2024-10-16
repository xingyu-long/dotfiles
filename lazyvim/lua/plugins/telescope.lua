return {
  "nvim-telescope/telescope.nvim",
  keys = {
    -- change a keymap
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
    { "<leader>fF", false },
    { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Grep" },
    { "<leader>sG", false },
  },
}
