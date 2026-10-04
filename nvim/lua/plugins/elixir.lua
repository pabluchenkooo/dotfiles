return {
  -- 1. Treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "elixir",
        "heex",
        "eex",
      })
    end,
  },
  -- 2. Language server
  {
    "elixir-tools/elixir-tools.nvim",
    version = "*",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("elixir").setup({
        nextls = { enable = false },
        elixirls = {
          enable = true,
          settings = require("elixir.elixirls").settings({
            fetchDeps = true,
          }),
        },
      })
    end,
  },
  -- 3. Git blame
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 500 },
    },
  },
}
