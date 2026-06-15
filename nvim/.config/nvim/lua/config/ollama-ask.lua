-- Lightweight one-shot Q&A against a local Ollama server.
-- Visual-mode <leader>aa → input question → streaming markdown popup.
-- Distinct from opencode.nvim: no agent, no tools, no session.

local M = {}

local function open_popup(title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"

  local width = math.min(100, math.floor(vim.o.columns * 0.7))
  local height = math.min(20, math.floor(vim.o.lines * 0.5))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].conceallevel = 2

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })

  return buf
end

local function set_lines(buf, lines)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
end

local function append(buf, text)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local last = vim.api.nvim_buf_line_count(buf) - 1
  local last_line = vim.api.nvim_buf_get_lines(buf, last, last + 1, false)[1] or ""
  local lines = vim.split(last_line .. text, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(buf, last, last + 1, false, lines)
end

local function ask(selection, question, filetype)
  local model = vim.g.ollama_ask_model or "qwen2.5-coder:7b"
  local url = (vim.g.ollama_ask_url or "http://localhost:11434") .. "/api/chat"
  local ft = filetype ~= "" and filetype or "text"

  local buf = open_popup("Ollama (" .. model .. ")")
  set_lines(buf, { "⏳ thinking…" })

  local body = vim.json.encode({
    model = model,
    stream = true,
    messages = {
      {
        role = "system",
        content = "You are a concise coding assistant. The user has selected a block of code and asks a question about it. Answer in markdown. Be direct, no preamble.",
      },
      {
        role = "user",
        content = string.format("```%s\n%s\n```\n\n%s", ft, selection, question),
      },
    },
  })

  local first_chunk = true
  local stderr_buf = {}

  vim.system(
    { "curl", "-sN", "-H", "Content-Type: application/json", "-d", body, url },
    {
      stdout = function(_, data)
        if not data then return end
        vim.schedule(function()
          for line in data:gmatch("[^\n]+") do
            local ok, msg = pcall(vim.json.decode, line)
            if ok and msg and msg.message and msg.message.content then
              if first_chunk then
                set_lines(buf, { "" })
                first_chunk = false
              end
              append(buf, msg.message.content)
            end
          end
        end)
      end,
      stderr = function(_, data)
        if data then table.insert(stderr_buf, data) end
      end,
    },
    function(out)
      vim.schedule(function()
        if out.code ~= 0 and first_chunk then
          set_lines(buf, {
            "**Error:** curl exited " .. tostring(out.code),
            "",
            "Is the Ollama server running? Try `ollama-start` in a terminal.",
            "",
            "```",
            table.concat(stderr_buf, ""),
            "```",
          })
        end
      end)
    end
  )
end

function M.setup()
  vim.keymap.set("x", "<leader>aa", function()
    vim.cmd('noautocmd normal! "vy')
    local selection = vim.fn.getreg("v")
    vim.fn.setreg("v", "")
    local filetype = vim.bo.filetype
    if selection == "" then
      vim.notify("ollama-ask: empty selection", vim.log.levels.WARN)
      return
    end
    vim.ui.input({ prompt = "Ask Ollama: " }, function(question)
      if not question or question == "" then return end
      ask(selection, question, filetype)
    end)
  end, { desc = "Ask Ollama about selection" })
end

return M
