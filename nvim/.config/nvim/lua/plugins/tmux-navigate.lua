-- Seamless C-h/j/k/l navigation between vim splits and tmux panes.
-- Loads only inside tmux. If herdr is nested inside tmux, $TMUX is still set,
-- so tmux wins and herdr-splits.lua stays disabled.
return {
  "sunaku/tmux-navigate",
  cond = vim.env.TMUX ~= nil,
}
