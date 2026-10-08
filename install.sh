#!/usr/bin/env bash
# Bootstrap a machine from this repo. Safe to re-run.
#   ./install.sh            # packages + links
#   ./install.sh --links    # only (re)create symlinks
#   ./install.sh --only nvim,tmux        # install + link just these components
#   ./install.sh --links --only nvim     # only (re)link just these components
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

log() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

# link <repo path> <target>: symlink, backing up anything already there
link() {
  local src="$DOTFILES/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then return; fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    mkdir -p "$BACKUP"; mv "$dst" "$BACKUP/"; log "backed up $dst -> $BACKUP/"
  fi
  ln -s "$src" "$dst"; log "linked $dst"
}

# seed <repo path> <target>: copy only if missing (for files apps rewrite themselves)
seed() {
  local src="$DOTFILES/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  [[ -e "$dst" ]] || { cp "$src" "$dst"; log "seeded $dst"; }
}

has() { command -v "$1" &>/dev/null; }

# components selectable with --only; each has a links_<name> and optionally an install_<name>
COMPONENTS=(zsh git tmux nvim lazygit k9s claude codex ghostty zed)

ensure_brew() {
  has brew && return
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

# apt-get install, running apt-get update once per run
apt_install() {
  [[ -n "${APT_UPDATED:-}" ]] || { sudo apt-get update; APT_UPDATED=1; }
  sudo apt-get install -y "$@"
}

# pkg <command> <brew formula> [apt package]: install if <command> is missing
pkg() {
  has "$1" && return
  if [[ "$OS" == "Darwin" ]]; then ensure_brew; brew install "$2"
  elif has apt-get; then apt_install "${3:-$2}"
  else echo "Unsupported OS — can't install $2." >&2; fi
}

# latest release version of a GitHub repo, without the leading "v"
gh_latest() {
  local tag
  tag="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest")"
  echo "${tag##*/v}"
}

# add a third-party apt repo: apt_repo <name> <key url> <repo line, KEYRING is replaced>
apt_repo() {
  local keyring="/etc/apt/keyrings/$1.gpg"
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL "$2" | sudo gpg --dearmor --yes -o "$keyring"
  echo "${3//KEYRING/$keyring}" | sudo tee "/etc/apt/sources.list.d/$1.list" >/dev/null
}

# Linux counterparts of the Brewfile: everyday CLI, networking, infra/cloud
install_linux_extras() {
  local deb_arch uname_arch
  deb_arch="$(dpkg --print-architecture)"   # amd64 | arm64
  uname_arch="$(uname -m)"                  # x86_64 | aarch64

  # ── apt repos for tools whose distro versions are missing or stale ─────────
  has gh || apt_repo github-cli https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    "deb [arch=$deb_arch signed-by=KEYRING] https://cli.github.com/packages stable main"
  has gcloud || apt_repo google-cloud https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    "deb [signed-by=KEYRING] https://packages.cloud.google.com/apt cloud-sdk main"
  if ! has op; then
    apt_repo 1password https://downloads.1password.com/linux/keys/1password.asc \
      "deb [arch=$deb_arch signed-by=KEYRING] https://downloads.1password.com/linux/debian/$deb_arch stable main"
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22 /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -fsSL https://downloads.1password.com/linux/debian/debsig/1password.pol \
      | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null
    curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
      | sudo gpg --dearmor --yes -o /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
  fi
  if ! has docker; then
    local distro codename
    distro="$(. /etc/os-release && echo "$ID")"            # ubuntu | debian
    codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    apt_repo docker "https://download.docker.com/linux/$distro/gpg" \
      "deb [arch=$deb_arch signed-by=KEYRING] https://download.docker.com/linux/$distro $codename stable"
  fi
  has node || curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

  sudo apt-get update
  sudo apt-get install -y gh nodejs age nmap wireguard-tools google-cloud-cli 1password-cli \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  # run docker without sudo (takes effect on next login)
  sudo usermod -aG docker "$USER"

  # ── everyday CLI ───────────────────────────────────────────────────────────
  install_claude
  has uv || curl -LsSf https://astral.sh/uv/install.sh | sh
  has just || curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to "$HOME/.local/bin"
  if ! has lazydocker; then
    local ld_version; ld_version="$(gh_latest jesseduffield/lazydocker)"
    curl -fsSL "https://github.com/jesseduffield/lazydocker/releases/download/v${ld_version}/lazydocker_${ld_version}_Linux_${uname_arch/aarch64/arm64}.tar.gz" \
      | sudo tar xz -C /usr/local/bin lazydocker
  fi
  if ! has yazi; then
    local tmp; tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/yazi.zip" \
      "https://github.com/sxyazi/yazi/releases/latest/download/yazi-${uname_arch}-unknown-linux-gnu.zip"
    unzip -q "$tmp/yazi.zip" -d "$tmp"
    sudo install "$tmp"/yazi-*/yazi "$tmp"/yazi-*/ya /usr/local/bin/
    rm -rf "$tmp"
  fi

  # ── networking ─────────────────────────────────────────────────────────────
  if ! has cloudflared; then
    curl -fsSL -o /tmp/cloudflared.deb \
      "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${deb_arch}.deb"
    sudo apt-get install -y /tmp/cloudflared.deb && rm /tmp/cloudflared.deb
  fi

  # ── infra / cloud ──────────────────────────────────────────────────────────
  if ! has tfenv; then
    git clone --depth=1 https://github.com/tfutils/tfenv.git "$HOME/.tfenv"
    ln -sf "$HOME"/.tfenv/bin/* "$HOME/.local/bin/"
  fi
  has terraform || { "$HOME/.local/bin/tfenv" install latest && "$HOME/.local/bin/tfenv" use latest; }
  has helm || curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  has hcloud || curl -fsSL "https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-${deb_arch}.tar.gz" \
    | sudo tar xz -C /usr/local/bin hcloud
  install_k9s
  install_codex
}

install_packages() {
  if [[ "$OS" == "Darwin" ]]; then
    ensure_brew
    brew bundle --file="$DOTFILES/Brewfile"
  elif has apt-get; then
    apt_install zsh git tmux curl unzip ripgrep fd-find direnv jq htop tree rsync build-essential
    install_nvim
    install_lazygit
    install_linux_extras
  else
    echo "Unsupported OS for package install — skipping." >&2
  fi
}

# ── components ───────────────────────────────────────────────────────────────

install_zsh() {
  pkg curl curl; pkg git git; pkg zsh zsh
  [[ -d "$HOME/.oh-my-zsh" ]] || RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  local p10k="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  [[ -d "$p10k" ]] || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k"
  if [[ "$SHELL" != *zsh ]]; then chsh -s "$(command -v zsh)" || true; fi
}
links_zsh() {
  link zsh/zshrc    "$HOME/.zshrc"
  link zsh/zprofile "$HOME/.zprofile"
  link zsh/p10k.zsh "$HOME/.p10k.zsh"
  if [[ ! -f "$HOME/.secrets.zsh" ]]; then
    cp "$DOTFILES/zsh/secrets.zsh.example" "$HOME/.secrets.zsh"; chmod 600 "$HOME/.secrets.zsh"
    log "created ~/.secrets.zsh from template — fill in your keys"
  fi
}

install_git() { pkg git git; }
links_git() {
  link git/gitconfig "$HOME/.gitconfig"
  link bin/git-pcom  "$HOME/bin/git-pcom"
  if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    read -rp "git name: " gname; read -rp "git email: " gemail
    printf '[user]\n\tname = %s\n\temail = %s\n' "$gname" "$gemail" > "$HOME/.gitconfig.local"
    log "created ~/.gitconfig.local"
  fi
}

install_tmux() {
  pkg git git; pkg tmux tmux
  [[ -d "$HOME/.tmux/plugins/tpm" ]] || git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
}
links_tmux() { link tmux/tmux.conf "$HOME/.tmux.conf"; }

# neovim plus what LazyVim needs (git, ripgrep, fd, a C compiler for treesitter)
install_nvim() {
  pkg curl curl; pkg git git; pkg rg ripgrep
  if [[ "$OS" == "Darwin" ]]; then pkg fd fd; pkg nvim neovim; return; fi
  pkg fdfind fd-find; pkg cc build-essential
  mkdir -p "$HOME/.local/bin"
  has fd || ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  # neovim from apt is usually too old for LazyVim — grab the release build
  if ! has nvim; then
    local arch; arch="$(uname -m)"; [[ "$arch" == "aarch64" ]] && arch="arm64"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch}.tar.gz" | sudo tar xz -C /opt
    sudo ln -sf "/opt/nvim-linux-${arch}/bin/nvim" /usr/local/bin/nvim
  fi
}
links_nvim() { link nvim "$HOME/.config/nvim"; }

install_lazygit() {
  if [[ "$OS" == "Darwin" ]]; then pkg lazygit lazygit; return; fi
  pkg curl curl
  # lazygit isn't in apt on older Debian/Ubuntu — grab the release build
  if ! has lazygit; then
    local lg_arch lg_version
    lg_arch="$(uname -m)"; [[ "$lg_arch" == "aarch64" ]] && lg_arch="arm64"
    lg_version="$(gh_latest jesseduffield/lazygit)"
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${lg_version}/lazygit_${lg_version}_Linux_${lg_arch}.tar.gz" \
      | sudo tar xz -C /usr/local/bin lazygit
  fi
}
links_lazygit() { link lazygit/config.yml "$HOME/.config/lazygit/config.yml"; }

install_k9s() {
  if [[ "$OS" == "Darwin" ]]; then pkg k9s derailed/k9s/k9s; return; fi
  pkg curl curl
  has k9s || curl -fsSL "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_$(dpkg --print-architecture).tar.gz" \
    | sudo tar xz -C /usr/local/bin k9s
}
links_k9s() { link k9s/config.yaml "$HOME/.config/k9s/config.yaml"; }

install_claude() {
  has claude && return
  if [[ "$OS" == "Darwin" ]]; then ensure_brew; brew install --cask claude-code@latest
  else pkg curl curl; curl -fsSL https://claude.ai/install.sh | bash; fi
}
links_claude() {
  link claude/statusline.sh "$HOME/.claude/statusline.sh"
  for skill in "$DOTFILES"/claude/skills/*/; do
    skill="$(basename "$skill")"
    link "claude/skills/$skill" "$HOME/.claude/skills/$skill"
  done
  seed claude/settings.json "$HOME/.claude/settings.json"
}

install_codex() {
  has codex && return
  if [[ "$OS" == "Darwin" ]]; then ensure_brew; brew install --cask codex
  elif has npm; then sudo npm install -g @openai/codex
  else echo "codex needs node/npm — run the full install first." >&2; fi
}
links_codex() {
  link codex/AGENTS.md   "$HOME/.codex/AGENTS.md"
  seed codex/config.toml "$HOME/.codex/config.toml"
}

links_ghostty() { link ghostty/config "$HOME/.config/ghostty/config"; }
links_zed() {
  link zed/settings.json "$HOME/.config/zed/settings.json"
  link zed/keymap.json   "$HOME/.config/zed/keymap.json"
}

link_all() {
  local c
  for c in "${COMPONENTS[@]}"; do
    # Ghostty and Zed configs are macOS-only
    [[ "$OS" != "Darwin" && ( "$c" == ghostty || "$c" == zed ) ]] && continue
    "links_$c"
  done
}

usage() {
  cat <<EOF
usage: $0 [--links] [--only <component>[,<component>...]]
  --links   only (re)create symlinks, don't install packages
  --only    install + link only these components: ${COMPONENTS[*]}
EOF
}

links_only=""; only=""
while (($#)); do
  case "$1" in
    --links)   links_only=1 ;;
    --only)    only="${2:?--only needs a component list}"; shift ;;
    --only=*)  only="${1#*=}" ;;
    -h|--help) usage; exit 0 ;;
    *)         echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if [[ -n "$only" ]]; then
  IFS=, read -ra selected <<< "$only"
  for c in "${selected[@]}"; do
    [[ " ${COMPONENTS[*]} " == *" $c "* ]] || { echo "unknown component: $c (choose from: ${COMPONENTS[*]})" >&2; exit 1; }
  done
  for c in "${selected[@]}"; do
    if [[ -z "$links_only" ]] && declare -F "install_$c" >/dev/null; then "install_$c"; fi
    "links_$c"
  done
  log "done."
  exit 0
fi

if [[ -z "$links_only" ]]; then
  install_packages
  install_zsh
  install_tmux
fi
link_all
log "done. Open tmux and press prefix (Ctrl-Space) + I to install tmux plugins."
