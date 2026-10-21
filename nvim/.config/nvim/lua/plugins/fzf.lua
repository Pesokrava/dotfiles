-- fzf-lua hides generated files by default; <leader>uG toggles them back in.
-- Patterns live in generated.ignore next to this config (fd/rg --ignore-file).
local ignore_file = vim.fn.stdpath("config") .. "/generated.ignore"
local hide = true
local base

-- Appends --ignore-file to the file/grep commands. grep's rg_opts ends in `-e`,
-- which must stay last, so the flag goes in front of it.
local function apply(target)
  local flag = hide and (" --ignore-file " .. vim.fn.shellescape(ignore_file)) or ""
  local function with(opt)
    return (opt:gsub(" %-e$", "")) .. flag .. (opt:match(" %-e$") or "")
  end
  target.files = vim.tbl_extend("force", target.files or {}, {
    fd_opts = with(base.files.fd_opts),
    rg_opts = with(base.files.rg_opts),
  })
  target.grep = vim.tbl_extend("force", target.grep or {}, {
    rg_opts = with(base.grep.rg_opts),
  })
end

return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  keys = {
    {
      "<leader>uG",
      function()
        hide = not hide
        apply(require("fzf-lua").config.setup_opts)
        vim.notify((hide and "Hiding" or "Showing") .. " generated files in fzf")
      end,
      desc = "Toggle generated files in fzf",
    },
  },
  opts = function(_, opts)
    local fzf = require("fzf-lua")
    local config = fzf.config
    config.defaults.keymap.fzf["alt-j"] = "down"
    config.defaults.keymap.fzf["alt-k"] = "up"
    base = {
      files = {
        fd_opts = opts.files and opts.files.fd_opts or fzf.defaults.files.fd_opts,
        rg_opts = opts.files and opts.files.rg_opts or fzf.defaults.files.rg_opts,
      },
      grep = {
        rg_opts = opts.grep and opts.grep.rg_opts or fzf.defaults.grep.rg_opts,
      },
    }
    apply(opts)
  end,
}
