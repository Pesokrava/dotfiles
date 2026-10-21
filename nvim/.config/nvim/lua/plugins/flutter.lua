return {
  "nvim-flutter/flutter-tools.nvim",
  cond = function()
    return vim.fn.executable("flutter") == 1
  end,
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim", -- optional for vim.ui.select
  },
  config = function()
    require("flutter-tools").setup({})
  end,
}
