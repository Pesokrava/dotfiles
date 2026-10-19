local utils = {}

function _G.set_trace()
  if vim.bo.filetype == "python" then
    -- Check if 'import ipdb' is in the file
    local ipdb_present = false
    for i = 1, vim.fn.line("$") do
      if string.find(vim.fn.getline(i), "import ipdb") then
        ipdb_present = true
        break
      end
    end

    -- If 'import ipdb' is not in the file, add it at the beginning or second line
    if not ipdb_present then
      local first_line = vim.fn.getline(1)
      if first_line == "from __future__ import annotations" then
        vim.api.nvim_buf_set_lines(0, 1, 1, false, { "import ipdb" })
      else
        vim.api.nvim_buf_set_lines(0, 0, 0, false, { "import ipdb" })
      end
    end

    -- Get the current line's indentation
    local indent = vim.fn.indent(".")
    local spaces = string.rep(" ", indent)

    -- Add 'ipdb.set_trace()' at the line above the cursor with the correct indentation
    local current_line = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, current_line - 1, current_line - 1, false, { spaces .. "ipdb.set_trace()" })
  end
end

function _G.clear_trace()
  if vim.bo.filetype == "python" then
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local new_lines = {}

    for _, line in ipairs(lines) do
      if not string.find(line, "import ipdb") and not string.find(line, "ipdb.set_trace()") then
        table.insert(new_lines, line)
      end
    end

    vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
  end
end

function utils.copy_relative_path_from_cwd()
  local file_path = vim.fn.expand("%:p")
  local relative_path = vim.fn.fnamemodify(file_path, ":.")
  vim.fn.setreg("+", relative_path)
  print("Copied: " .. relative_path)
end

function utils.copy_agent_line_ref()
  local relative_path = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
  local ref = "@" .. relative_path .. " line " .. vim.fn.line(".")
  vim.fn.setreg("+", ref)
  print("Copied: " .. ref)
end

return utils
