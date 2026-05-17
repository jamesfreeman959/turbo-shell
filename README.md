# turbo-shell

A one-command terminal environment for macOS, Ubuntu Server, and Bluefin Linux. Bootstrap any machine and get the same consistent setup: Ghostty, tmux with session persistence, Neovim/LazyVim, and a curated set of modern CLI tools.

## What it installs

| Category | Tools |
|---|---|
| Terminal | Ghostty + Monaspace Nerd Font |
| Multiplexer | tmux (oh-my-tmux) + tmux-continuum + sesh + tmuxinator |
| Shell | zsh + starship prompt + atuin history + zoxide |
| Editor | Neovim + LazyVim |
| Modern CLI | lsd, bat, delta, difftastic, lazygit, ripgrep, fd, fzf, yazi, btop |
| Remote | Mosh (auto-attaches to tmux on connect) |

## Quick start

```bash
git clone https://github.com/jamesfreeman959/turbo-shell.git
cd turbo-shell
bash bootstrap.sh
```

The bootstrap detects your OS and runs the right script. Existing configs are backed up to `~/.config_backup_<timestamp>` before being replaced.

After the bootstrap, follow the steps in [GETTING_STARTED.md](GETTING_STARTED.md) to install tmux plugins and finish the Neovim setup.

## Supported platforms

| Platform | Script |
|---|---|
| macOS | `bootstrap_macos.sh` |
| Ubuntu Server 22.04 / 24.04 (x86\_64 + arm64) | `bootstrap_ubuntu.sh` |
| Bluefin / Aurora (Universal Blue) | `bootstrap_bluefin.sh` |

You can also run a platform script directly if you want to skip auto-detection.

## Key features

**Mosh + tmux auto-attach** — connect via Mosh and your workspace is exactly where you left it; tmux-continuum restores it across reboots.

**Unified keybindings** — `Ctrl+h/j/k/l` moves between Neovim splits and tmux panes seamlessly. `Ctrl+a` is an alias for the tmux prefix (GNU Screen-compatible alongside `Ctrl+b`).

**helpme cheatsheet viewer** — `helpme tmux`, `helpme nvim` etc. renders the included cheatsheets with glow and fzf. Run `helpme` alone for a fuzzy picker.

**Chezmoi-ready** — configs are plain files you can register with Chezmoi for multi-machine sync. See [CHEZMOI.md](CHEZMOI.md). The tmux clipboard line is the only per-platform variation and ships as a Chezmoi template.

## Documentation

| File | Contents |
|---|---|
| [GETTING_STARTED.md](GETTING_STARTED.md) | Post-bootstrap manual steps and quick-reference tables |
| [NEW_TOOLS_CHEATSHEET.md](NEW_TOOLS_CHEATSHEET.md) | What replaces what and how to use each tool |
| [TMUX_CHEATSHEET.md](TMUX_CHEATSHEET.md) | Full tmux key binding reference |
| [NEOVIM_CHEATSHEET.md](NEOVIM_CHEATSHEET.md) | LazyVim key binding reference |
| [MC_CHEATSHEET.md](MC_CHEATSHEET.md) | Midnight Commander reference, Mac laptop adapted |
| [PLATFORMS.md](PLATFORMS.md) | Platform-specific notes (Ubuntu quirks, Bluefin/Wayland, etc.) |
| [CHEZMOI.md](CHEZMOI.md) | Chezmoi integration and day-to-day sync workflow |

## License

MIT
