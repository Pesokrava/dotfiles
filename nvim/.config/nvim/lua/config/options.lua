-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.nu = true
vim.g.autoformat = false
vim.o.autoread = true

-- LazyVim defaults to 2-space indentation; use 4 everywhere instead.
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

-- ---------------------------------------------------------------------------
-- Clipboard
-- ---------------------------------------------------------------------------
-- LazyVim sets clipboard=unnamedplus by default. Reset it so that plain y/d/p
-- use only Neovim's own registers. <leader>y / <leader>p (keymaps.lua) are the
-- explicit way to interact with the system clipboard.
vim.opt.clipboard = ""

-- Use OSC 52 escape sequences for clipboard access in remote/headless
-- environments where native clipboard tools (pbcopy, xclip, wl-copy) are not
-- available. The host terminal intercepts these escape sequences and writes the
-- payload to the system clipboard.
--
-- Triggers:
--   - LIMA_INSTANCE: set by limactl shell (macOS Lima VM)
--   - SSH_TTY: set when connected via SSH
--   - No native clipboard tool detected
local function use_osc52()
  if vim.env.LIMA_INSTANCE then
    return true
  end
  if vim.env.SSH_TTY then
    return true
  end
  -- On a local machine, check if a native clipboard tool exists
  if vim.fn.has("mac") == 1 then
    return false -- macOS always has pbcopy
  end
  -- Linux: check for xclip, xsel, or wl-copy
  if vim.fn.executable("xclip") == 1
    or vim.fn.executable("xsel") == 1
    or vim.fn.executable("wl-copy") == 1 then
    return false
  end
  -- No clipboard tool found — fall back to OSC 52
  return true
end

if use_osc52() then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end
