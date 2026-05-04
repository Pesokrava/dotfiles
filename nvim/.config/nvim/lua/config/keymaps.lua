-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymap_set = vim.keymap.set
vim.keymap.set = function(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  return keymap_set(mode, lhs, rhs, opts)
end

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "wO", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>")
vim.keymap.set("n", "wo", "<Cmd>call append(line('.'),     repeat([''], v:count1))<CR>")

vim.keymap.set("n", "<leader>d", '"_d', { desc = "Delete into black hole" })
vim.keymap.set("v", "<leader>d", '"_d', { desc = "Delete into black hole" })

vim.keymap.set("n", "gh", vim.lsp.buf.hover)
vim.keymap.set("n", "J", "mzJ`z`")
vim.keymap.set("n", "K", "i<CR><Esc>", { noremap = true })
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<leader>y", '"+y', { desc = "Yank into system clipboard" })
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank into system clipboard" })
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("v", "<leader>p", '"+p', { desc = "Paste from system clipboard" })

vim.keymap.set("n", "<leader>rr", vim.lsp.buf.rename, { desc = "Refactor" })

vim.keymap.set("n", "<leader>cui", "<cmd>TransferInit<cr>", { desc = "Init transfer in the current repo" })
vim.keymap.set("n", "<leader>cuf", "<cmd>DiffRemote<cr>", { desc = "Remote diff of the current file" })
vim.keymap.set("n", "<leader>cuu", "<cmd>TransferUpload<cr>", { desc = "Upload current file to remote" })
vim.keymap.set("n", "<leader>cud", "<cmd>TransferDownload<cr>", { desc = "Download current file from remote" })
-- vim.keymap.set("n", "<leader>sr", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
-- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

vim.keymap.set(
  "n",
  "<leader>fh",
  "<cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files,-u<cr>",
  { desc = "Find all files" }
)
vim.keymap.set(
  "n",
  "<leader>fG",
  ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
  { desc = "Live grep with args" }
)

-- quick kebinding to hide virtual text
local isLspDiagnosticsVisible = true
vim.keymap.set("n", "<leader>cx", function()
  isLspDiagnosticsVisible = not isLspDiagnosticsVisible
  vim.diagnostic.config({
    virtual_text = isLspDiagnosticsVisible,
    underline = isLspDiagnosticsVisible,
  })
end, { desc = "Hide virtual text LSP" })

vim.api.nvim_set_keymap(
  "n",
  "<leader>dw",
  ":lua set_trace()<CR>",
  { noremap = true, silent = true, desc = "Ipdb breakpoint" }
)
vim.api.nvim_set_keymap(
  "n",
  "<leader>dq",
  ":lua clear_trace()<CR>",
  { noremap = true, silent = true, desc = "Clear all ipdb breakpoints" }
)

vim.api.nvim_set_keymap(
  "n",
  "<leader>fp",
  ':lua vim.cmd([[let @+=expand("%:p:h")]])<CR>',
  { desc = "Copy current directory path", noremap = true, silent = true }
)

vim.api.nvim_set_keymap(
  "n",
  "<leader>fP",
  ':lua require("config.utils").copy_relative_path_from_cwd()<CR>',
  { desc = "Copy relative file path from CWD", noremap = true, silent = true }
)

vim.keymap.set("n", "<leader>fw", function()
  require("fzf-lua").files({ cwd = vim.fn.input("Dir: ", vim.fn.getcwd(), "dir") })
end, { desc = "Find files in dir" })

vim.keymap.set("n", "<leader>fe", function()
  local ext = vim.fn.input("Extension: ")
  if ext == "" then return end
  require("fzf-lua").files({ cmd = "fd --type f --extension " .. ext })
end, { desc = "Find files by extension" })

vim.keymap.set("n", "<leader>fW", function()
  local dir = vim.fn.input("Dir: ", vim.fn.getcwd(), "dir")
  local ext = vim.fn.input("Extension (empty=all): ")
  local cmd = ext ~= "" and ("fd --type f --extension " .. ext) or nil
  require("fzf-lua").files({ cwd = dir, cmd = cmd })
end, { desc = "Find files (dir + extension)" })


-- This function toggles the conceal level between 0 and 2
function toggle_conceal()
  local level = vim.wo.conceallevel
  if level == 0 then
    vim.wo.conceallevel = 2
  else
    vim.wo.conceallevel = 0
  end
end

vim.api.nvim_set_keymap(
  "n",
  "<leader>tc",
  "<cmd>lua toggle_conceal()<CR>",
  { noremap = true, silent = true, desc = "Toggle Conceal" }
)

-- Function to toggle between Catppuccin Frappe and Latte themes
function Toggle_catppuccin_theme()
  if vim.g.colors_name == "catppuccin-frappe" then
    vim.cmd("colorscheme catppuccin-latte")
  else
    vim.cmd("colorscheme catppuccin-frappe")
  end
end

-- Keybinding to toggle Catppuccin themes
vim.keymap.set("n", "<leader>tt", "<cmd>lua Toggle_catppuccin_theme()<CR>", { desc = "Toggle Catppuccin Theme" })
