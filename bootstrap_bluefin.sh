#!/usr/bin/env bash
# bootstrap_bluefin.sh — Bluefin Linux (Fedora immutable) workstation setup
# Tested on: Bluefin / Aurora / Bazzite (Fedora 40+)
#
# Bluefin is an immutable OS. System packages go via rpm-ostree (requires reboot),
# but Homebrew (pre-installed on Bluefin) handles user-space CLI tools — same
# as macOS. GUI apps go via Flatpak.
#
# This script installs nearly the same environment as macOS:
# Ghostty (Flatpak) + tmux + Neovim + all shell tools.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS="$REPO_DIR/configs"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()    { echo -e "${GREEN}▶${NC} $1"; }
warn()   { echo -e "${YELLOW}⚠${NC}  $1"; }
info()   { echo -e "${BLUE}ℹ${NC}  $1"; }
header() { echo -e "\n${BOLD}── $1 ──${NC}"; }

backup_if_exists() {
  if [[ -e "$1" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp -r "$1" "$BACKUP_DIR/"
    warn "Backed up: $1 → $BACKUP_DIR/"
  fi
}

# ── 0. Verify Homebrew ────────────────────────────────────────────────────────
header "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for the rest of this script
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
  info "Homebrew found at $(brew --prefix)"
fi

log "Updating Homebrew..."
brew update --quiet

# ── 1. CLI tools via Homebrew ─────────────────────────────────────────────────
# Identical to macOS — Homebrew on Linux has the same formulae.
header "Homebrew packages"

BREW_PACKAGES=(
  tmux
  neovim
  fzf
  zoxide
  atuin
  yazi
  lsd
  glow
  bat
  ripgrep
  fd
  git-delta
  difftastic
  lazygit
  btop
  tmuxinator
)

for pkg in "${BREW_PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null 2>&1; then
    info "$pkg already installed"
  else
    brew install "$pkg"
    log "Installed $pkg"
  fi
done

# sesh (FZF session manager)
if ! brew list sesh &>/dev/null 2>&1; then
  brew tap joshmedeski/sesh 2>/dev/null || true
  brew install sesh
  log "Installed sesh"
else
  info "sesh already installed"
fi

# wl-clipboard — needed for tmux-yank and extrakto on Wayland
if ! command -v wl-copy >/dev/null 2>&1; then
  if command -v rpm-ostree >/dev/null 2>&1; then
    warn "Installing wl-clipboard via rpm-ostree — a REBOOT will be required after this script"
    sudo rpm-ostree install -y wl-clipboard 2>/dev/null || warn "rpm-ostree install failed — install wl-clipboard manually and reboot"
  fi
else
  info "wl-clipboard already installed"
fi

# ── 2. Ghostty via Flatpak ────────────────────────────────────────────────────
header "Ghostty (Flatpak)"
if ! flatpak list --app | grep -qi ghostty 2>/dev/null; then
  # Ensure Flathub is configured (pre-configured on Bluefin, but be safe)
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
  log "Installing Ghostty from Flathub..."
  flatpak install -y flathub com.mitchellh.ghostty \
    || warn "Ghostty Flatpak install failed. Try: flatpak search ghostty to find the correct ID."
else
  info "Ghostty already installed via Flatpak"
fi

# Deploy Ghostty config
# Flatpak Ghostty reads config from the same location as native builds
mkdir -p "$HOME/.config/ghostty"
backup_if_exists "$HOME/.config/ghostty/config"
cp "$CONFIGS/ghostty/config" "$HOME/.config/ghostty/config"
log "Deployed ~/.config/ghostty/config"

# ── 3. MonaspiceNe Nerd Font ──────────────────────────────────────────────────
# Homebrew on Linux doesn't have casks. Install font to ~/.local/share/fonts/.
header "MonaspiceNe Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"
if ls "$FONT_DIR"/MonaspiceNe*.ttf &>/dev/null 2>&1; then
  info "MonaspiceNe Nerd Font already installed"
else
  log "Downloading MonaspiceNe Nerd Font..."
  mkdir -p "$FONT_DIR"
  FONT_URL=$(curl -s "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" \
    | grep "browser_download_url.*Monaspace.tar.xz" \
    | head -1 \
    | sed 's/.*"browser_download_url": "\(.*\)"/\1/')

  if [[ -n "$FONT_URL" ]]; then
    curl -sL "$FONT_URL" | tar -xJ -C "$FONT_DIR"
    fc-cache -fv "$FONT_DIR" >/dev/null 2>&1
    log "Installed MonaspiceNe Nerd Font"
  else
    warn "Could not find Monaspace font release. Install manually:"
    warn "  https://github.com/ryanoasis/nerd-fonts/releases — download Monaspace.tar.xz"
    warn "  Extract TTFs to ~/.local/share/fonts/ then run: fc-cache -fv"
  fi
fi

# ── 4. oh-my-tmux + TPM ──────────────────────────────────────────────────────
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

# ── 5. Deploy configs ─────────────────────────────────────────────────────────
header "Deploying configs"

# tmux — fix clipboard for Wayland (pbcopy → wl-copy)
backup_if_exists "$HOME/.tmux.conf.local"
cp "$CONFIGS/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
sed -i "s/@extrakto_clip_tool 'pbcopy'/@extrakto_clip_tool 'wl-copy'/" "$HOME/.tmux.conf.local"
log "Deployed ~/.tmux.conf.local (clipboard: wl-copy for Wayland)"
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
mkdir -p "$HOME/.local/bin"
install -m 755 "$REPO_DIR/scripts/tmux-ip" "$HOME/.local/bin/tmux-ip"
log "Deployed tmux-ip → ~/.local/bin/tmux-ip"

# ── 6. git config ─────────────────────────────────────────────────────────────
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
log "Configured git (delta + difftastic)"

# ── 7. Shell: ensure zsh + Homebrew env ──────────────────────────────────────
header "zsh + Homebrew env"
ZSHRC="$HOME/.zshrc"
[[ ! -f "$ZSHRC" ]] && touch "$ZSHRC"

# Inject Homebrew environment if not already present
BREW_ENV='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
if ! grep -q "linuxbrew" "$ZSHRC" 2>/dev/null; then
  echo "" >> "$ZSHRC"
  echo "# Homebrew (Linux)" >> "$ZSHRC"
  echo "$BREW_ENV" >> "$ZSHRC"
  log "Added Homebrew env to ~/.zshrc"
else
  info "Homebrew env already in ~/.zshrc"
fi

# Ensure zsh is the default shell
if [[ "$SHELL" != "$(command -v zsh)" ]]; then
  log "Setting zsh as default shell..."
  chsh -s "$(command -v zsh)" || warn "chsh failed — set your default shell manually"
else
  info "zsh is already the default shell"
fi

# ── 8. zshrc plugin ──────────────────────────────────────────────────────────
header "~/.zshrc plugin"
PLUGIN_DIR="$HOME/.zsh/plugins"
MARKER="# >>> turbo-shell additions <<<"

mkdir -p "$PLUGIN_DIR"
ln -sf "$REPO_DIR/zshrc_additions.zsh" "$PLUGIN_DIR/turbo-shell.plugin.zsh"
log "Symlinked zshrc_additions.zsh → ~/.zsh/plugins/turbo-shell.plugin.zsh"

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
echo -e "${GREEN}${BOLD}✓ Bluefin bootstrap complete!${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
if rpm-ostree status 2>/dev/null | grep -q "wl-clipboard"; then
  echo -e "  ${YELLOW}0. REBOOT required — rpm-ostree installed wl-clipboard${NC}"
fi
echo "  1. Log out and back in (shell change to zsh takes effect)"
echo "  2. Open Ghostty (search in GNOME Activities or: flatpak run com.mitchellh.ghostty)"
echo "     If theme doesn't load: ghostty +list-themes | grep -i tokyo"
echo "  3. Start a fresh tmux session: tmux kill-server && tmux new -s main"
echo "     oh-my-tmux changes prefix to Ctrl+a — press Ctrl+a then capital I to install plugins"
echo "  4. Run 'nvim' → LazyVim installs plugins on first launch → :Mason then U"
echo "  5. Set atuin server URL: ~/.config/atuin/config.toml"
echo "     Then: atuin import auto && atuin register -u USER -e EMAIL"
echo ""
[[ -d "$BACKUP_DIR" ]] && echo -e "${BLUE}Backups: $BACKUP_DIR${NC}"
