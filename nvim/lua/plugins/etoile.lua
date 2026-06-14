return {
  {
    "tadashi-aikawa/etoile.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>e", "<cmd>Etoile<cr>", desc = "Etoile (file tree)" },
      { "<leader>E", "<cmd>EtoileCurrent<cr>", desc = "Etoile (current dir)" },
    },
    opts = {},
  },
}
