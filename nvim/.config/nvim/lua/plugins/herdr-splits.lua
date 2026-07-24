-- herdr equivalent of tmux-navigate: seamless C-h/j/k/l between vim splits and
-- herdr panes. Loads only inside herdr AND not inside tmux, so when herdr is
-- nested in tmux the tmux plugin wins (see tmux-navigate.lua).
return {
  "lmilojevicc/herdr-splits.nvim",
  cond = vim.env.HERDR_ENV == "1" and vim.env.TMUX == nil,
  opts = {},
  keys = {
    { "<C-h>", function() require("herdr-splits").move_cursor_left() end },
    { "<C-j>", function() require("herdr-splits").move_cursor_down() end },
    { "<C-k>", function() require("herdr-splits").move_cursor_up() end },
    { "<C-l>", function() require("herdr-splits").move_cursor_right() end },
  },
}
