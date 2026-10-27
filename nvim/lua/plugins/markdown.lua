return {
  -- Disable render-markdown.nvim (no inline rendering needed)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = false,
  },

  -- Disable markdownlint (no warnings needed)
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },
}
