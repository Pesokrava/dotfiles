-- Build the ensure_installed list dynamically based on available runtimes.
-- Tools for languages whose runtime is not on PATH are skipped.
local tools = {
  "stylua",
  "shellcheck",
  "shfmt",
}

local has = vim.fn.executable

if has("python3") == 1 then
  vim.list_extend(tools, { "pyright", "flake8" })
end

if has("go") == 1 then
  vim.list_extend(tools, { "gopls" })
end

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(tool)
        return tool ~= "codelldb"
      end, opts.ensure_installed or {})
      vim.list_extend(opts.ensure_installed, tools)
    end,
  },
}
