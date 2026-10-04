# dotfiles

Config for my Mac and any fresh VPS.

## New machine

```sh
git clone git@github.com:<you>/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

- **macOS**: installs Homebrew + everything in `Brewfile`, then symlinks configs.
- **Debian/Ubuntu VPS**: installs zsh, tmux, neovim, ripgrep, fd, direnv, git via apt, then symlinks (skips Ghostty/Zed).
- Existing files get moved to `~/.dotfiles-backup/<timestamp>/` before linking.
- `./install.sh --links` only re-links, without installing packages.

After install:
1. Fill in `~/.secrets.zsh` (API keys; template in `zsh/secrets.zsh.example`). **Never commit it.**
2. Git name/email are asked once and saved to `~/.gitconfig.local` (not tracked).
3. Copy SSH keys over (`~/.ssh/`) — not stored here.
4. In tmux: `Ctrl-Space` then `I` to install plugins.
5. Open `nvim` once so LazyVim installs plugins.

## What's here

| Path | Linked to |
|---|---|
| `zsh/zshrc`, `zprofile`, `p10k.zsh` | `~/.zshrc`, `~/.zprofile`, `~/.p10k.zsh` |
| `git/gitconfig` | `~/.gitconfig` |
| `tmux/tmux.conf` | `~/.tmux.conf` (catppuccin, resurrect, continuum) |
| `nvim/` | `~/.config/nvim` (LazyVim) |
| `ghostty/`, `zed/` | `~/.config/…` (macOS only) |
| `lazygit/`, `k9s/` | `~/.config/…` |
| `claude/` | `~/.claude` (statusline, skills; settings seeded once) |

Claude skills: `code-constitution`, `elixir-antipatterns`, `review-branch`, `review-colleague-pr`, `address-pr-review`, `load-vault`. The review skills write to your notes vault when `NOTES_VAULT` is set (put it in `~/.zshrc.local`), otherwise to `.reviews/<branch>/` in the repo.
| `codex/` | `~/.codex` (AGENTS.md linked, config seeded once) |
| `bin/` | `~/bin` |
| `macos/catppuccin-macchiato.itermcolors` | import manually in iTerm2 |

Settings files that apps rewrite themselves (Claude/Codex `settings.json`/`config.toml`) are **copied** on first install rather than symlinked, so they don't get clobbered.

## Updating

```sh
brew bundle dump --file=~/dotfiles/Brewfile --force   # after installing new brew stuff
cd ~/dotfiles && git add -A && git commit -m "update" && git push
```

Machine-specific shell tweaks go in `~/.zshrc.local` (not tracked).
