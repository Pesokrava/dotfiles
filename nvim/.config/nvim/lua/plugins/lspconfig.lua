-- Build the servers table dynamically based on available runtimes.
local has = vim.fn.executable

local servers = {
  -- Global keymaps for all LSP servers
  ["*"] = {
    keys = {
      { "K", "i<CR><Esc>", mode = "n", noremap = true },
    },
  },
  cssls = {
    settings = {
      css = {
        validate = true,
      },
      less = {
        validate = true,
      },
      scss = {
        validate = true,
      },
    },
  },
  yamlls = {
    -- Have to add this for yamlls to understand that we support line folding
    capabilities = {
      textDocument = {
        foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true,
        },
      },
    },
    -- lazy-load schemastore when needed
    on_new_config = function(new_config)
      new_config.settings.yaml.schemas = vim.tbl_deep_extend(
        "force",
        new_config.settings.yaml.schemas or {},
        require("schemastore").yaml.schemas()
      )
    end,
    settings = {
      redhat = { telemetry = { enabled = false } },
      yaml = {
        keyOrdering = false,
        format = {
          enable = true,
        },
        validate = true,
        schemaStore = {
          -- Must disable built-in schemaStore support to use
          -- schemas from SchemaStore.nvim plugin
          enable = false,
          -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
          url = "",
        },
      },
    },
  },
}

if has("arduino-cli") == 1 then
  servers.arduino_language_server = {
    cmd = {
      "arduino-language-server",
      "-cli-config",
      vim.fn.expand("~/Library/Arduino15/arduino-cli.yaml"),
      -- ponytail: hardcoded Uno; per-sketch boards go in sketch.yaml default_fqbn
      "-fqbn",
      "arduino:avr:uno",
    },
  }
end

if has("python3") == 1 then
  servers.pyright = {
    settings = {
      pyright = {},
      python = {},
    },
  }
end

if has("go") == 1 then
  servers.gopls = {
    settings = {
      gopls = {
        -- Load integration-tagged files (//go:build integration) so gopls has
        -- package metadata for them — otherwise InlayHint/diagnostics/completion
        -- fail with "no package metadata for file".
        buildFlags = { "-tags=integration" },
        analyses = {
          ST1000 = false, -- Disable package comment requirement (rest handled by lazyvim extra)
        },
      },
    },
  }
end

-- Resolved once per session, through the shim, so a toolchain bump is picked up
-- on restart instead of being hardcoded.
local goroot_cache
local function goroot_bin()
  if not goroot_cache then
    goroot_cache = vim.trim(vim.fn.system({ "go", "env", "GOROOT" })) .. "/bin"
  end
  return goroot_cache
end

return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = servers,
      setup = {
        -- Disable LazyVim's obsolete gopls semanticTokensProvider workaround:
        -- modern gopls advertises semantic tokens itself, and the LazyVim hack
        -- both crashes on missing client.textDocument capabilities and produces
        -- a legend that mismatches gopls's actual token indices.
        gopls = function(_, _) end,
      },
    },
  },
  -- Lint Go in-editor with golangci-lint. nvim-lint's builtin lints the file's
  -- package dir (not the single file), so cross-file symbols resolve — no more
  -- false "undefined" positives. It also auto-picks the v2 output flags.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      -- golangci-lint reads the file from disk, not the buffer. Linting on
      -- InsertLeave runs ~900ms before auto-save's deferred write lands, so it
      -- re-reports the pre-edit file and looks like a stale warning. Writes are
      -- the only point the on-disk content changed, so they are the only trigger.
      events = { "BufWritePost", "BufReadPost" },
      linters_by_ft = {
        go = { "golangcilint" },
      },
      linters = {
        -- nvim-lint spawns linters in nvim's cwd. In a multi-module monorepo
        -- with no go.work that cwd has no go.mod, so golangci-lint resolved no
        -- module and reported every import as a `typecheck` error. Run it from
        -- the buffer's own module, and point it at the buffer's package dir
        -- (the builtin's own dir-vs-file choice is decided once at load time,
        -- in the wrong cwd).
        golangcilint = function()
          local linter = vim.deepcopy(require("lint.linters.golangcilint"))
          local dir = vim.fn.expand("%:p:h")
          linter.cwd = vim.fs.root(dir, "go.mod") or dir
          -- golangci-lint shells out to `go env`/`go list` several times per
          -- run, and proto's `go` shim costs ~1s per invocation: 6.6s vs 0.35s
          -- on control/services/populator. Put the real toolchain bin ahead of
          -- the shims. nvim-lint replaces the whole environment when `env` is
          -- set, so HOME has to be carried over — GOCACHE/GOPATH derive from it.
          linter.env = { PATH = goroot_bin() .. ":" .. vim.env.PATH, HOME = vim.env.HOME }
          linter.args[#linter.args] = function()
            return dir
          end
          return linter
        end,
      },
    },
    -- golangci-lint resolves the Go module from its own process cwd, and
    -- nvim-lint runs it in nvim's cwd (lint.lua: `linter.cwd or getcwd()`).
    -- In a multi-module repo without go.work, opening nvim above the module
    -- puts that cwd outside every go.mod, so typecheck reports every import
    -- as "no required module provides package ...". Pin each run to the
    -- module that owns the buffer.
    init = function()
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("golangcilint_module_cwd", { clear = true }),
        pattern = "*.go",
        callback = function(ev)
          local dir = vim.fs.root(ev.buf, "go.mod")
          if dir then
            require("lint").linters.golangcilint.cwd = dir
          end
        end,
      })
    end,
  },
}
