#!/usr/bin/env bash
# install_to_chezmoi.sh — push configs from this repo into Chezmoi management
#
# Run this after bootstrap has deployed configs to ~/ and you want Chezmoi
# to start managing (and syncing) them across your macOS and Bluefin machines.
#
# What this does:
#   - Adds each config file to Chezmoi's source directory
#   - Installs a Chezmoi template for ~/.tmux.conf.local so the clipboard
#     tool resolves correctly per platform (pbcopy / wl-copy / tmux buffer)
#   - Does NOT touch package installation or bootstrap scripts
#   - Safe to re-run — chezmoi add is idempotent
#
# What it does NOT add to Chezmoi:
#   - ~/.zshrc  (too machine-specific; managed by bootstrap append only)
#   - ~/.tmux.conf  (symlink to oh-my-tmux; managed by bootstrap)
#   - ~/.config/nvim/{init.lua,lua/config/lazy.lua}  (LazyVim boilerplate)
#   - ~/.local/share/nvim/  (lazy.nvim plugin cache — not config)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()    { echo -e "${GREEN}▶${NC} $1"; }
warn()   { echo -e "${YELLOW}⚠${NC}  $1"; }
info()   { echo -e "${BLUE}ℹ${NC}  $1"; }
header() { echo -e "\n${BOLD}── $1 ──${NC}"; }
skip()   { echo -e "  ${BLUE}↷${NC}  skipping $1 ($2)"; }

# ── Preflight checks ─────────────────────────────────────────────────────────
header "Preflight"

if ! command -v chezmoi >/dev/null 2>&1; then
  echo -e "${RED}✗${NC} chezmoi not found."
  echo "  Install it first: https://chezmoi.io/install/"
  echo "  macOS:   brew install chezmoi"
  echo "  Bluefin: brew install chezmoi"
  exit 1
fi
log "chezmoi found at $(command -v chezmoi)"

# Verify that bootstrap has been run by checking a key deployed file
if [[ ! -f "$HOME/.tmux.conf.local" ]]; then
  echo -e "${RED}✗${NC} ~/.tmux.conf.local not found."
  echo "  Run bootstrap first so configs are deployed to ~/ before adding them to Chezmoi."
  echo "  macOS:   bash bootstrap_macos.sh"
  echo "  Bluefin: bash bootstrap_bluefin.sh"
  exit 1
fi
log "Bootstrap appears to have run — proceeding"

CHEZMOI_SOURCE=$(chezmoi source-path)
log "Chezmoi source directory: $CHEZMOI_SOURCE"

# ── tmux.conf.local — template version ───────────────────────────────────────
# This is the only config that differs per platform (clipboard tool).
# We install a Chezmoi template rather than a plain file so it resolves
# correctly on each machine at 'chezmoi apply' time.
header "~/.tmux.conf.local (template)"

TMPL_DEST="$CHEZMOI_SOURCE/dot_tmux.conf.local.tmpl"
PLAIN_DEST="$CHEZMOI_SOURCE/dot_tmux.conf.local"

# Remove a plain version if chezmoi add was run previously
if [[ -f "$PLAIN_DEST" ]]; then
  rm "$PLAIN_DEST"
  warn "Removed plain dot_tmux.conf.local (replacing with template)"
fi

cp "$REPO_DIR/configs/tmux/tmux.conf.local.chezmoi.tmpl" "$TMPL_DEST"
log "Installed dot_tmux.conf.local.tmpl → $TMPL_DEST"

# ── Plain config files — chezmoi add ─────────────────────────────────────────
# chezmoi add reads from the deployed location (~/) and registers it in the
# source directory. It's idempotent — running it again just updates the source
# if the deployed file has changed.
header "Config files"

add_if_exists() {
  local path="$1"
  local label="${2:-$1}"
  if [[ -e "$path" ]]; then
    chezmoi add "$path"
    log "Added $label"
  else
    skip "$label" "not deployed on this machine"
  fi
}

# Starship prompt
add_if_exists "$HOME/.config/starship.toml" "~/.config/starship.toml"

# atuin history sync
add_if_exists "$HOME/.config/atuin/config.toml" "~/.config/atuin/config.toml"

# Ghostty terminal (present on macOS + Bluefin, absent on Ubuntu Server)
add_if_exists "$HOME/.config/ghostty/config" "~/.config/ghostty/config"

# tmuxinator session templates
add_if_exists "$HOME/.config/tmuxinator/main.yml" "~/.config/tmuxinator/main.yml"
add_if_exists "$HOME/.config/tmuxinator/llm.yml"  "~/.config/tmuxinator/llm.yml"

# Neovim — only our overlay files, not the LazyVim boilerplate
add_if_exists "$HOME/.config/nvim/lua/config/options.lua" "~/.config/nvim/lua/config/options.lua"
add_if_exists "$HOME/.config/nvim/lua/config/keymaps.lua" "~/.config/nvim/lua/config/keymaps.lua"
add_if_exists "$HOME/.config/nvim/lua/plugins/extras.lua" "~/.config/nvim/lua/plugins/extras.lua"
add_if_exists "$HOME/.config/nvim/lua/plugins/lang.lua"   "~/.config/nvim/lua/plugins/lang.lua"

# ── Review ────────────────────────────────────────────────────────────────────
header "Review"
echo ""
echo "Chezmoi diff (what 'chezmoi apply' would change on this machine):"
echo ""
chezmoi diff || true   # diff exits non-zero when there are changes — that's fine

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}✓ Done!${NC} All configs are now tracked by Chezmoi."
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo "  On THIS machine — verify the template renders correctly:"
echo "    chezmoi apply --dry-run"
echo "    chezmoi apply"
echo ""
echo "  On OTHER managed machines (after syncing your Chezmoi source repo):"
echo "    chezmoi update   # pull latest + apply"
echo "    # or if starting fresh:"
echo "    chezmoi init <your-chezmoi-repo-url>"
echo "    chezmoi apply"
echo ""
echo "  When you update a config in THIS repo in future:"
echo "    1. bash bootstrap_<platform>.sh  # re-deploy to ~/"
echo "    2. bash install_to_chezmoi.sh    # update Chezmoi source"
echo "    3. Push your Chezmoi source repo"
echo "    4. chezmoi update on other machines"
echo ""
echo "  See CHEZMOI.md for full workflow documentation."
