#!/usr/bin/env bash
# bootstrap.sh — OS detection dispatcher
# Detects your platform and delegates to the appropriate bootstrap script.
# You can also run the platform scripts directly:
#   macOS:   bash bootstrap_macos.sh
#   Ubuntu:  bash bootstrap_ubuntu.sh
#   Bluefin: bash bootstrap_bluefin.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
    return
  fi

  if [[ ! -f /etc/os-release ]]; then
    echo "unsupported"
    return
  fi

  # shellcheck source=/dev/null
  source /etc/os-release

  case "${ID:-}" in
    ubuntu|debian|linuxmint)
      echo "ubuntu"
      ;;
    fedora|rhel|centos|almalinux|rocky)
      # Universal Blue images (Bluefin, Aurora, Bazzite) are Fedora-based
      # and have rpm-ostree + Homebrew pre-installed. Detect by checking
      # for the ublue image marker or an active Homebrew installation.
      if [[ -f /usr/share/ublue-os/image-info.json ]] || \
         grep -qi "bluefin\|aurora\|bazzite\|ublue" /etc/os-release 2>/dev/null || \
         command -v brew >/dev/null 2>&1; then
        echo "bluefin"
      else
        echo "fedora"
      fi
      ;;
    *)
      echo "unsupported"
      ;;
  esac
}

OS=$(detect_os)

case "$OS" in
  macos)
    echo -e "${GREEN}▶${NC} macOS detected — running bootstrap_macos.sh"
    exec bash "$REPO_DIR/bootstrap_macos.sh" "$@"
    ;;
  ubuntu)
    echo -e "${GREEN}▶${NC} Ubuntu/Debian detected — running bootstrap_ubuntu.sh"
    exec bash "$REPO_DIR/bootstrap_ubuntu.sh" "$@"
    ;;
  bluefin)
    echo -e "${GREEN}▶${NC} Bluefin/Universal Blue detected — running bootstrap_bluefin.sh"
    exec bash "$REPO_DIR/bootstrap_bluefin.sh" "$@"
    ;;
  fedora)
    echo -e "${YELLOW}⚠${NC}  Standard Fedora detected (not an immutable image)."
    echo    "   The Bluefin script may work if you install Homebrew first."
    echo    "   Run manually: bash bootstrap_bluefin.sh"
    exit 1
    ;;
  *)
    echo -e "${RED}✗${NC} Unsupported OS. Run the appropriate script directly:"
    echo    "   macOS:   bash bootstrap_macos.sh"
    echo    "   Ubuntu:  bash bootstrap_ubuntu.sh"
    echo    "   Bluefin: bash bootstrap_bluefin.sh"
    exit 1
    ;;
esac
