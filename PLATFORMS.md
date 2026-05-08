# Platform Notes

The config files in `configs/` are identical across all platforms. Only installation
and a handful of runtime behaviours differ. Run `bash bootstrap.sh` on any supported
machine — it auto-detects the OS and calls the right script.

---

## Supported platforms

| Platform | Script | Use case |
|---|---|---|
| macOS | `bootstrap_macos.sh` | macOS (reference platform) |
| Ubuntu Server LTS | `bootstrap_ubuntu.sh` | Headless servers — connected to via Mosh |
| Bluefin Linux | `bootstrap_bluefin.sh` | Linux workstation (Fedora immutable) |

---

## macOS

**Package manager:** Homebrew (`brew` formulas + casks)

No significant quirks. This is the reference platform everything else was designed against.

**Font:** Installed via `brew install --cask font-monaspace-nerd-font`

**Clipboard:** `pbcopy` / `pbpaste` — native macOS, works automatically in tmux-yank and extrakto.

---

## Ubuntu Server LTS

**Tested on:** 22.04 LTS, 24.04 LTS — x86_64 and arm64

### Package management

A mix of sources is required because Ubuntu's apt repositories lag significantly behind
upstream for developer tooling:

| Tool | Install method | Reason |
|---|---|---|
| tmux, fzf, ripgrep, btop, bat, fd | `apt` | Available and recent enough |
| lsd | GitHub releases `.deb` (bootstrap handles this) | Not in Ubuntu main repos |
| neovim | `snap install nvim --classic` | apt version is very old (0.6 on 22.04) |
| starship | Official install script | Not in apt |
| atuin | Official install script | Not in apt |
| zoxide | Official install script | Not in apt |
| delta, difftastic, lazygit, yazi, sesh | GitHub release binaries | Not in apt |
| tmuxinator | `gem install` | Ruby gem |

If `snapd` is not available (minimal server images sometimes omit it), the bootstrap
falls back to downloading the official Neovim tarball from GitHub releases and
installing it to `~/.local/nvim/`.

### Binary name quirks: bat and fd

Ubuntu ships `bat` as **`batcat`** and `fd` as **`fdfind`** to avoid conflicts with
unrelated packages that already owned those names in the Debian ecosystem.

The bootstrap resolves this by creating symlinks in `~/.local/bin/`:

```bash
~/.local/bin/bat  → /usr/bin/batcat
~/.local/bin/fd   → /usr/bin/fdfind
```

`~/.local/bin` is at the front of `$PATH`, so `bat` and `fd` work everywhere —
including inside FZF preview commands, which run in a subshell where aliases
don't apply.

`zshrc_additions.zsh` also contains alias guards as a belt-and-braces fallback
for any machine where the symlinks weren't created:

```zsh
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
fi
```

### Clipboard

Ubuntu Server is **headless** — there is no display server or clipboard daemon.
tmux-yank and extrakto are configured to use the **tmux buffer** instead of a
system clipboard. Text copied inside tmux stays in tmux's paste buffer (`Ctrl+a ]`
to paste).

If you later attach a display to the server or run it with X11/Wayland forwarding,
install `xclip` or `wl-clipboard` and update these lines in `~/.tmux.conf.local`:

```bash
# Change:
set -g @extrakto_clip_tool 'tmux'
# To (X11):
set -g @extrakto_clip_tool 'xclip'
# Or (Wayland):
set -g @extrakto_clip_tool 'wl-copy'
```

tmux-yank will auto-detect `xclip`, `xsel`, or `wl-copy` if they are present — no
change needed for yank itself.

### No Ghostty, no fonts

Ubuntu Server has no display server. Ghostty and font installation are skipped
entirely. You connect *to* these servers from your Mac or Bluefin machine, where
Ghostty is already running.

### zsh

Ubuntu ships with bash as the default shell. The bootstrap installs zsh via apt
and calls `chsh` to change your default. **This requires a log-out/log-in to take
effect** — the running session stays in bash until you reconnect.

### Architecture

The bootstrap detects `uname -m` and downloads the correct binary for your
architecture. Both `x86_64` and `arm64` (aarch64) are supported for all GitHub
release downloads.

---

## Bluefin Linux

**Tested on:** Bluefin, Aurora (Fedora 40+, rpm-ostree immutable)

Bluefin is an immutable OS. The system root is read-only and managed by
`rpm-ostree`. Changes to the system layer require a reboot. The Bluefin project's
answer to this for developer tooling is **Homebrew** — it's pre-installed and runs
entirely in user-space under `/home/linuxbrew/`. This means the Bluefin bootstrap
is nearly identical to macOS.

### Package management

| Tool | Install method |
|---|---|
| All CLI tools (tmux, nvim, fzf, atuin, lsd, bat, delta…) | Homebrew formula — identical to macOS |
| Ghostty | Flatpak (`com.mitchellh.ghostty`) |
| MonaspiceNe Nerd Font | Downloaded from Nerd Fonts GitHub releases to `~/.local/share/fonts/` |
| wl-clipboard | `rpm-ostree install` — requires reboot |

Homebrew on Linux does not have **casks** (macOS-only). GUI apps go via Flatpak instead.

### Ghostty

Installed from Flathub:

```bash
flatpak install flathub com.mitchellh.ghostty
```

The Flatpak reads config from the same location as a native build
(`~/.config/ghostty/config`), so the deployed config works without modification.

If the install fails because the Flatpak ID has changed, find the correct one with:

```bash
flatpak search ghostty
```

To launch from the terminal:

```bash
flatpak run com.mitchellh.ghostty
```

### Font installation

Homebrew casks don't exist on Linux. The bootstrap downloads the Monaspace Nerd Font
archive from the Nerd Fonts GitHub releases and extracts it to `~/.local/share/fonts/`,
then runs `fc-cache` to register it with the font system.

If the automated download fails, install manually:

1. Download `Monaspace.tar.xz` from https://github.com/ryanoasis/nerd-fonts/releases
2. Extract: `tar -xJf Monaspace.tar.xz -C ~/.local/share/fonts/`
3. Rebuild cache: `fc-cache -fv`

### Clipboard

Bluefin uses **Wayland** as its display server. The macOS `pbcopy` command does not
exist. The bootstrap patches `~/.tmux.conf.local` after deployment:

```bash
sed -i "s/@extrakto_clip_tool 'pbcopy'/@extrakto_clip_tool 'wl-copy'/" ~/.tmux.conf.local
```

`wl-clipboard` (`wl-copy` / `wl-paste`) must be installed for this to work. Because
it's a system package it goes via `rpm-ostree`:

```bash
rpm-ostree install wl-clipboard
# then reboot
```

tmux-yank auto-detects `wl-copy` once it's present — no further config needed.

### wl-clipboard and the reboot requirement

`rpm-ostree install` stages the change but does not apply it until the system boots
into the new deployment. The bootstrap warns you if it triggered an rpm-ostree
install. **Reboot before expecting clipboard integration to work.**

After the reboot, verify with:

```bash
echo "test" | wl-copy && wl-paste
```

### Homebrew environment

The bootstrap ensures this is in `~/.zshrc`:

```zsh
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

If Homebrew-installed tools aren't found in a new shell, this line is missing or
sourced too late. It must appear before any `command -v brew` checks.

### Detection

The auto-detect in `bootstrap.sh` identifies Bluefin/Aurora/Bazzite by checking for:

1. `/usr/share/ublue-os/image-info.json` (Universal Blue marker file)
2. The strings `bluefin`, `aurora`, `bazzite`, or `ublue` in `/etc/os-release`
3. A working `brew` installation (strong signal on an immutable Fedora image)

Standard (mutable) Fedora will match condition 3 if you've installed Homebrew
manually. The Bluefin bootstrap is safe to run on standard Fedora — it just won't
have handled the system-level packages for you.

---

## Config portability summary

| Config file | Portable? | Notes |
|---|---|---|
| `configs/nvim/` | ✅ Identical | LazyVim downloads its own plugins |
| `configs/starship/starship.toml` | ✅ Identical | |
| `configs/atuin/config.toml` | ✅ Identical | |
| `configs/tmuxinator/*.yml` | ✅ Identical | |
| `configs/ghostty/config` | ✅ Identical | Skipped on Ubuntu Server |
| `configs/tmux/tmux.conf.local` | ⚠️ Patched | `pbcopy` → `tmux` (Ubuntu) or `wl-copy` (Bluefin) |
| `zshrc_additions.zsh` | ✅ Identical | Contains guarded shims for batcat/fdfind |

The tmux clipboard line is the only config that differs at runtime. The bootstrap
scripts handle the patch automatically with `sed` after copying the file.
