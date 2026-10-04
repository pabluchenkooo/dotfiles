return {
  -- Install the candidate colorschemes so you can preview them live.
  -- catppuccin + tokyonight already ship with LazyVim; add the rest.
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "catppuccin/nvim", name = "catppuccin", lazy = true },

  -- Set the active colorscheme here. Change the value, save, and
  -- restart nvim (or :colorscheme <name>) to switch for good.
  {
    "LazyVim/LazyVim",
    opts = {
      -- Options to try:
      --   "catppuccin-mocha"  "catppuccin-macchiato"  "catppuccin-frappe"
      --   "gruvbox"
      --   "kanagawa-wave"  "kanagawa-dragon"  "kanagawa-lotus" (light)
      --   "rose-pine"  "rose-pine-moon"  "rose-pine-dawn" (light)
      --   "tokyonight"  (your current default)
      colorscheme = "catppuccin-mocha",
    },
  },
}
