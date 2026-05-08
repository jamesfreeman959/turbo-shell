#!/usr/bin/env bash
# bootstrap_ubuntu.sh — Ubuntu Server LTS terminal setup
# Tested on: Ubuntu 22.04 LTS, 24.04 LTS (x86_64 and arm64)
#
# This installs the same terminal environment as macOS but headless:
# no Ghostty, no fonts. Focus is on tmux + Neovim + shell tools.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS="$REPO_DIR/configs"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
LOCAL_BIN="$HOME/.local/bin"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()    { echo -e "${GREEN}▶${NC} $1"; }
warn()   { echo -e "${YELLOW}⚠${NC}  $1"; }
info()   { echo -e "${BLUE}ℹ${NC}  $1"; }
header() { echo -e "\n${BOLD}── $1 ──${NC}"; }
die()    { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

backup_if_exists() {
  if [[ -e "$1" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$1" "$BACKUP_DIR/"
    warn "Backed up: $1 → $BACKUP_DIR/"
  fi
}

# Detect architecture — used throughout for binary downloads
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH_DEB="amd64"; ARCH_GO="amd64";  ARCH_MUSL="x86_64"  ;;
  aarch64) ARCH_DEB="arm64"; ARCH_GO="arm64";   ARCH_MUSL="aarch64" ;;
  *) die "Unsupported architecture: $ARCH" ;;
esac

# Download the latest GitHub release asset matching a pattern, install to LOCAL_BIN
# Usage: gh_install <owner/repo> <asset-pattern> <binary-name> [strip-components]
gh_install() {
  local repo="$1"
  local pattern="$2"
  local binary_name="$3"
  local strip="${4:-1}"

  log "Installing $binary_name from $repo..."

  local url
  url=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" \
    | grep "browser_download_url" \
    | grep "$pattern" \
    | head -1 \
    | sed 's/.*"browser_download_url": "\(.*\)"/\1/')

  [[ -z "$url" ]] && { warn "No release found for $repo ($pattern) — skipping"; return 1; }

  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' RETURN

  curl -sL "$url" -o "$tmpdir/asset"

  if [[ "$url" == *.tar.gz ]] || [[ "$url" == *.tgz ]]; then
    tar -xzf "$tmpdir/asset" -C "$tmpdir" 2>/dev/null || true
  elif [[ "$url" == *.tar.xz ]]; then
    tar -xJf "$tmpdir/asset" -C "$tmpdir" 2>/dev/null || true
  elif [[ "$url" == *.zip ]]; then
    unzip -q "$tmpdir/asset" -d "$tmpdir" 2>/dev/null || true
  fi

  # Find the binary — first try by name, then fallback to executable files
  local src
  src=$(find "$tmpdir" -name "$binary_name" -type f 2>/dev/null | head -1)
  [[ -z "$src" ]] && src=$(find "$tmpdir" -maxdepth 2 -type f -perm /111 ! -name "*.sh" | head -1)
  [[ -z "$src" ]] && src="$tmpdir/asset"  # raw binary fallback

  install -m 755 "$src" "$LOCAL_BIN/$binary_name"
  log "Installed $binary_name → $LOCAL_BIN/$binary_name"
}

# ── 0. Prerequisites ──────────────────────────────────────────────────────────
header "Prerequisites"

mkdir -p "$LOCAL_BIN"
# Ensure ~/.local/bin is in PATH for this session
export PATH="$LOCAL_BIN:$PATH"

log "Updating apt..."
sudo apt-get update -qq

log "Installing base dependencies..."
sudo apt-get install -y --no-install-recommends \
  zsh \
  tmux \
  mosh \
  git \
  curl \
  wget \
  unzip \
  fzf \
  ripgrep \
  btop \
  bat \
  fd-find \
  ruby-full \
  build-essential \
  ca-certificates

# ── Ubuntu binary name quirks — fix with symlinks ─────────────────────────────
# 'bat' is installed as 'batcat' and 'fd' as 'fdfind' on Ubuntu to avoid
# conflicts with unrelated packages. Symlink them to the expected names.
if command -v batcat >/dev/null 2>&1 && [[ ! -f "$LOCAL_BIN/bat" ]]; then
  ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
  log "Symlinked batcat → ~/.local/bin/bat"
fi
if command -v fdfind >/dev/null 2>&1 && [[ ! -f "$LOCAL_BIN/fd" ]]; then
  ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
  log "Symlinked fdfind → ~/.local/bin/fd"
fi

# ── 1. Neovim ─────────────────────────────────────────────────────────────────
header "Neovim"
# Prefer snap (simplest, always latest). Fall back to tarball if snap unavailable.
if command -v snap >/dev/null 2>&1; then
  if ! snap list nvim &>/dev/null 2>&1; then
    sudo snap install nvim --classic
    log "Installed neovim via snap"
  else
    info "neovim snap already installed"
  fi
else
  warn "snapd not available — installing Neovim via tarball"
  NVIM_ASSET="nvim-linux-${ARCH}.tar.gz"
  NVIM_URL=$(curl -s "https://api.github.com/repos/neovim/neovim/releases/latest" \
    | grep "browser_download_url.*${NVIM_ASSET}" \
    | head -1 \
    | sed 's/.*"browser_download_url": "\(.*\)"/\1/')
  curl -sL "$NVIM_URL" | tar -xz -C /tmp
  rm -rf ~/.local/nvim
  mv "/tmp/nvim-linux-${ARCH}" ~/.local/nvim
  ln -sf ~/.local/nvim/bin/nvim "$LOCAL_BIN/nvim"
  log "Installed neovim → $LOCAL_BIN/nvim"
fi

# ── 2. lsd ────────────────────────────────────────────────────────────────────
header "lsd"
if ! command -v lsd >/dev/null 2>&1; then
  LSD_URL=$(curl -s "https://api.github.com/repos/lsd-rs/lsd/releases/latest" \
    | grep "browser_download_url.*_${ARCH_DEB}\.deb" \
    | head -1 \
    | sed 's/.*"browser_download_url": "\(.*\)"/\1/')
  if [[ -n "$LSD_URL" ]]; then
    tmpfile=$(mktemp /tmp/lsd.XXXXXX.deb)
    curl -sL "$LSD_URL" -o "$tmpfile"
    sudo dpkg -i "$tmpfile"
    rm -f "$tmpfile"
    log "Installed lsd"
  else
    warn "Could not find lsd .deb for ${ARCH_DEB} — install manually: https://github.com/lsd-rs/lsd/releases"
  fi
else
  info "lsd already installed"
fi

# ── glow — terminal markdown viewer ──────────────────────────────────────────
header "glow"
if ! command -v glow >/dev/null 2>&1; then
  GLOW_URL=$(curl -s "https://api.github.com/repos/charmbracelet/glow/releases/latest" \
    | grep "browser_download_url.*_${ARCH_DEB}\.deb" \
    | head -1 \
    | sed 's/.*"browser_download_url": "\(.*\)"/\1/')
  if [[ -n "$GLOW_URL" ]]; then
    tmpfile=$(mktemp /tmp/glow.XXXXXX.deb)
    curl -sL "$GLOW_URL" -o "$tmpfile"
    sudo dpkg -i "$tmpfile"
    rm -f "$tmpfile"
    log "Installed glow"
  else
    warn "Could not find glow .deb for ${ARCH_DEB} — install manually: https://github.com/charmbracelet/glow/releases"
  fi
else
  info "glow already installed"
fi

# ── 3. Tools via official install scripts ─────────────────────────────────────
header "starship, atuin, zoxide"

if ! command -v starship >/dev/null 2>&1; then
  log "Installing starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "$LOCAL_BIN" -y
else
  info "starship already installed"
fi

if ! command -v atuin >/dev/null 2>&1; then
  log "Installing atuin..."
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
else
  info "atuin already installed"
fi

if ! command -v zoxide >/dev/null 2>&1; then
  log "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
    | sh -s -- --bin-dir "$LOCAL_BIN"
else
  info "zoxide already installed"
fi

# ── 4. Tools via GitHub releases ─────────────────────────────────────────────
header "GitHub release binaries"

# git-delta — syntax-highlighted diffs
if ! command -v delta >/dev/null 2>&1; then
  gh_install "dandavison/delta" "${ARCH_MUSL}-unknown-linux-musl.tar.gz" "delta"
else
  info "delta already installed"
fi

# difftastic — semantic side-by-side diffs
if ! command -v difft >/dev/null 2>&1; then
  gh_install "Wilfred/difftastic" "${ARCH_MUSL}-unknown-linux-musl.tar.gz" "difft"
else
  info "difft already installed"
fi

# lazygit — TUI git client
if ! command -v lazygit >/dev/null 2>&1; then
  gh_install "jesseduffield/lazygit" "Linux_${ARCH_GO}.tar.gz" "lazygit"
else
  info "lazygit already installed"
fi

# yazi — TUI file manager
if ! command -v yazi >/dev/null 2>&1; then
  gh_install "sxyazi/yazi" "yazi-${ARCH_MUSL}-unknown-linux-musl.zip" "yazi"
else
  info "yazi already installed"
fi

# sesh — tmux session manager (used by t-smart-tmux-session-manager)
if ! command -v sesh >/dev/null 2>&1; then
  gh_install "joshmedeski/sesh" "sesh_Linux_${ARCH_GO}.tar.gz" "sesh"
else
  info "sesh already installed"
fi

# btop (fallback if apt version is too old)
if ! command -v btop >/dev/null 2>&1; then
  gh_install "aristocratos/btop" "btop-${ARCH_MUSL}-linux-musl.tbz" "btop"
fi

# ── 5. tmuxinator ─────────────────────────────────────────────────────────────
header "tmuxinator"
if ! gem list tmuxinator -i >/dev/null 2>&1; then
  gem install tmuxinator --no-document
  log "Installed tmuxinator"
else
  info "tmuxinator already installed"
fi

# ── 6. zsh as default shell ───────────────────────────────────────────────────
header "zsh"
if [[ "$SHELL" != "$(command -v zsh)" ]]; then
  log "Setting zsh as default shell..."
  chsh -s "$(command -v zsh)"
  warn "Shell change takes effect on next login"
else
  info "zsh is already the default shell"
fi

# ── 7. oh-my-tmux + TPM ──────────────────────────────────────────────────────
header "oh-my-tmux + TPM"
if [[ ! -d "$HOME/.oh-my-tmux" ]]; then
  git clone https://github.com/gpakosz/.tmux.git "$HOME/.oh-my-tmux"
  ln -sf "$HOME/.oh-my-tmux/.tmux.conf" "$HOME/.tmux.conf"
  log "Installed oh-my-tmux"
else
  info "oh-my-tmux already installed"
  [[ ! -L "$HOME/.tmux.conf" ]] && ln -sf "$HOME/.oh-my-tmux/.tmux.conf" "$HOME/.tmux.conf"
fi

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  mkdir -p "$HOME/.tmux/plugins"
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  log "Installed TPM"
else
  info "TPM already installed"
fi

# ── 8. Deploy configs ─────────────────────────────────────────────────────────
header "Deploying configs"

# tmux
backup_if_exists "$HOME/.tmux.conf.local"
cp "$CONFIGS/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
# Linux: no pbcopy — on a headless server we use tmux's own buffer.
# tmux-yank will auto-detect xclip/xsel/wl-copy if a display is available.
sed -i "s/@extrakto_clip_tool 'pbcopy'/@extrakto_clip_tool 'tmux'/" "$HOME/.tmux.conf.local"
log "Deployed ~/.tmux.conf.local (clipboard: tmux buffer)"
if tmux info &>/dev/null 2>&1; then
  tmux source-file "$HOME/.tmux.conf" 2>/dev/null && log "Reloaded tmux config into running server" \
    || warn "Could not reload tmux config — start a new session to pick it up"
fi

# Neovim
if [[ -d "$HOME/.config/nvim" ]]; then
  backup_if_exists "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim"
fi
[[ -d "$HOME/.local/share/nvim" ]] && { backup_if_exists "$HOME/.local/share/nvim"; rm -rf "$HOME/.local/share/nvim"; }
git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
rm -rf "$HOME/.config/nvim/.git"
cp "$CONFIGS/nvim/lua/config/options.lua"  "$HOME/.config/nvim/lua/config/options.lua"
cp "$CONFIGS/nvim/lua/config/keymaps.lua"  "$HOME/.config/nvim/lua/config/keymaps.lua"
mkdir -p "$HOME/.config/nvim/lua/plugins"
cp "$CONFIGS/nvim/lua/plugins/extras.lua"  "$HOME/.config/nvim/lua/plugins/extras.lua"
cp "$CONFIGS/nvim/lua/plugins/lang.lua"    "$HOME/.config/nvim/lua/plugins/lang.lua"
rm -f "$HOME/.config/nvim/lua/plugins/example.lua"
log "Deployed LazyVim config"

# Starship
backup_if_exists "$HOME/.config/starship.toml"
cp "$CONFIGS/starship/starship.toml" "$HOME/.config/starship.toml"
log "Deployed ~/.config/starship.toml"

# atuin
mkdir -p "$HOME/.config/atuin"
backup_if_exists "$HOME/.config/atuin/config.toml"
cp "$CONFIGS/atuin/config.toml" "$HOME/.config/atuin/config.toml"
log "Deployed ~/.config/atuin/config.toml"

# tmuxinator
mkdir -p "$HOME/.config/tmuxinator"
cp "$CONFIGS/tmuxinator/main.yml" "$HOME/.config/tmuxinator/main.yml"
cp "$CONFIGS/tmuxinator/llm.yml"  "$HOME/.config/tmuxinator/llm.yml"
log "Deployed tmuxinator templates"

# Cheatsheets — available via 'helpme' command
mkdir -p "$HOME/.local/share/cheatsheets"
cp "$REPO_DIR/TMUX_CHEATSHEET.md"      "$HOME/.local/share/cheatsheets/tmux.md"
cp "$REPO_DIR/NEOVIM_CHEATSHEET.md"    "$HOME/.local/share/cheatsheets/nvim.md"
cp "$REPO_DIR/NEW_TOOLS_CHEATSHEET.md" "$HOME/.local/share/cheatsheets/tools.md"
cp "$REPO_DIR/GETTING_STARTED.md"      "$HOME/.local/share/cheatsheets/start.md"
log "Deployed cheatsheets to ~/.local/share/cheatsheets/ (use 'helpme' to browse)"

# tmux-ip helper — used by status bar to show primary IPv4
install -m 755 "$REPO_DIR/scripts/tmux-ip" "$LOCAL_BIN/tmux-ip"
log "Deployed tmux-ip → $LOCAL_BIN/tmux-ip"

# ── 9. bat theme ─────────────────────────────────────────────────────────────
header "bat theme"
BAT_THEMES_DIR="$(bat --config-dir)/themes"
TOKYO_THEME="$BAT_THEMES_DIR/tokyonight_night.tmTheme"
if [[ ! -f "$TOKYO_THEME" ]]; then
  mkdir -p "$BAT_THEMES_DIR"
  log "Downloading Tokyo Night theme for bat..."
  curl -fsSL "https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme" \
    -o "$TOKYO_THEME"
  bat cache --build
  log "bat theme installed and cache rebuilt"
else
  info "bat Tokyo Night theme already installed"
fi

# ── 10. git config ─────────────────────────────────────────────────────────────
header "git config"
git config --global core.pager             delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate         true
git config --global delta.side-by-side     true
git config --global delta.line-numbers     true
git config --global delta.light            false
git config --global delta.syntax-theme     "tokyonight_night"
git config --global merge.conflictstyle    diff3
git config --global diff.colorMoved        default
git config --global difftool.difftastic.cmd 'difft "$LOCAL" "$REMOTE"'
git config --global difftool.prompt        false
git config --global alias.dft             'difftool --tool difftastic'
log "Configured git (delta pager + difftastic tool)"

# ── 11. zshrc plugin ─────────────────────────────────────────────────────────
header "~/.zshrc plugin"
ZSHRC="$HOME/.zshrc"
PLUGIN_DIR="$HOME/.zsh/plugins"
MARKER="# >>> turbo-shell additions <<<"

mkdir -p "$PLUGIN_DIR"
ln -sf "$REPO_DIR/zshrc_additions.zsh" "$PLUGIN_DIR/turbo-shell.plugin.zsh"
log "Symlinked zshrc_additions.zsh → ~/.zsh/plugins/turbo-shell.plugin.zsh"

[[ ! -f "$ZSHRC" ]] && touch "$ZSHRC"
if grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
  info "Plugin source line already in ~/.zshrc"
else
  printf '\n%s\n%s\n%s\n' \
    "$MARKER" \
    '[[ -f "$HOME/.zsh/plugins/turbo-shell.plugin.zsh" ]] && source "$HOME/.zsh/plugins/turbo-shell.plugin.zsh"' \
    "# <<< turbo-shell additions >>>" >> "$ZSHRC"
  log "Added plugin source line to ~/.zshrc"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}✓ Ubuntu bootstrap complete!${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "  1. Log out and back in (shell change to zsh takes effect)"
echo "  2. Start a fresh tmux session: tmux kill-server && tmux new -s main"
echo "     oh-my-tmux changes prefix to Ctrl+a — press Ctrl+a then capital I to install plugins"
echo "  3. Run 'nvim' — LazyVim installs plugins on first launch"
echo "     Then run :Mason and press U to install language servers"
echo "  4. Set atuin server URL: ~/.config/atuin/config.toml"
echo "     Then: atuin import auto && atuin register -u USER -e EMAIL"
echo ""
[[ -d "$BACKUP_DIR" ]] && echo -e "${BLUE}Backups: $BACKUP_DIR${NC}"
