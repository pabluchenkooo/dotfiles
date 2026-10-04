return {
  -- Minuet AI: LLM-powered code completion
  {
    "milanglacier/minuet-ai.nvim",
    event = "InsertEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("minuet").setup({
        -- ── Provider ──────────────────────────────────────────────
        -- Set the API key as an environment variable (see notes at
        -- the bottom of this file).
        -- Codestral (Mistral's code model) — small, fast, purpose-built
        -- for fill-in-the-middle completion. Free API key from Mistral.
        provider = "codestral",

        -- Only surface warnings/errors (set to "verbose" to debug).
        notify = "warn",

        -- Latency-friendly defaults so it doesn't fire on every keystroke
        request_timeout = 3,
        throttle = 1500, -- ms: min gap between requests
        debounce = 600, -- ms: wait for typing to settle

        provider_options = {
          codestral = {
            model = "codestral-latest",
            end_point = "https://codestral.mistral.ai/v1/fim/completions",
            api_key = "CODESTRAL_API_KEY", -- env var name, not the key
            stream = true,
            optional = {
              max_tokens = 256,
              stop = { "\n\n" }, -- stop at a blank line
            },
          },
        },

        -- ── Ghost text (Copilot-style inline suggestions) ─────────
        virtualtext = {
          auto_trigger_ft = { "*" }, -- suggest in all filetypes
          keymap = {
            -- NOTE: on macOS these fire only with the LEFT ⌥ key
            -- (ghostty: macos-option-as-alt = left). Right ⌥ types accents.
            -- Avoid Shift'd combos like <A-A> — they're unreliable in the terminal.
            accept = "<A-a>", -- accept whole suggestion (Left ⌥ + a)
            accept_line = "<A-l>", -- accept one line
            accept_n_lines = "<A-z>", -- accept N lines (prompts for N)
            prev = "<A-[>",
            next = "<A-]>",
            dismiss = "<A-e>",
          },
        },
      })

      -- ── Recolor the ghost text to purple/magenta ───────────────
      -- MinuetVirtualText is the highlight group used for inline
      -- suggestions. Re-applied on every colorscheme change so it
      -- survives you switching themes.
      local function set_minuet_hl()
        vim.api.nvim_set_hl(0, "MinuetVirtualText", { fg = "#bb9af7", italic = true })
      end
      set_minuet_hl()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_minuet_hl,
      })

      -- ── Global toggle for ghost text (Left ⌥ + t) ──────────────
      -- minuet's own toggle only flips a buffer-local flag, and its
      -- FileType autocmd re-enables ghost text on every new buffer —
      -- so a plain toggle never "stays off". We track a global flag
      -- and re-assert it on each buffer/insert so "off" actually sticks.
      vim.g.minuet_virtualtext_off = false
      local function set_minuet(enabled)
        vim.g.minuet_virtualtext_off = not enabled
        vim.b.minuet_virtual_text_auto_trigger = enabled
        vim.notify("Minuet ghost text " .. (enabled and "enabled" or "disabled"))
      end
      vim.keymap.set({ "n", "i" }, "<A-t>", function()
        set_minuet(vim.g.minuet_virtualtext_off) -- flip: was-off → enable, was-on → disable
      end, { desc = "Toggle Minuet ghost text (global)" })
      vim.api.nvim_create_autocmd({ "BufEnter", "InsertEnter" }, {
        callback = function()
          if vim.g.minuet_virtualtext_off then
            vim.b.minuet_virtual_text_auto_trigger = false
          end
        end,
        desc = "Enforce global Minuet ghost-text disable across buffers",
      })
    end,
  },

  -- ── blink.cmp integration (suggestions in the completion menu) ─
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        -- manually trigger a minuet completion in the popup
        ["<A-y>"] = {
          function(cmp)
            cmp.show({ providers = { "minuet" } })
          end,
        },
      },
      sources = {
        -- appended to LazyVim's default sources (blink uses opts_extend)
        default = { "minuet" },
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            timeout_ms = 3000,
            score_offset = 50, -- rank minuet items above LSP
          },
        },
      },
    },
  },
}

-- ─────────────────────────────────────────────────────────────────
-- SETUP NOTES
-- Provider: Codestral (Mistral), fill-in-the-middle completion.
-- 1. Put your API key in ~/.secrets.zsh:
--        export CODESTRAL_API_KEY="your-key-here"
--    Then reload:  source ~/.zshrc   (or restart the terminal)
-- 2. Launch nvim, run  :Lazy sync  to install.
-- 3. Verify with  :checkhealth minuet   (checks the key is found).
-- 4. If requests fail, run  :Minuet  and check :messages for the
--    HTTP error; confirm the model id and that /chat/completions is
--    reachable from your network.
-- ─────────────────────────────────────────────────────────────────
