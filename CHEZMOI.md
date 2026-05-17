# Chezmoi Integration

## The relationship between this repo and Chezmoi

This repo is a **self-contained framework** — it stores configs, documents them, and
can bootstrap any machine without Chezmoi. Chezmoi is a **deployment layer** on top
of it for managed machines (macOS and Bluefin).

```
This repo (source of truth for config development)
    │
    │  bash bootstrap_<platform>.sh
    │  (installs packages + deploys configs to ~/)
    ▼
~/ (deployed configs)
    │
    │  bash install_to_chezmoi.sh
    │  (registers deployed files with Chezmoi)
    ▼
~/.local/share/chezmoi/ (Chezmoi source directory)
    │
    │  git push  (your Chezmoi dotfiles repo)
    │  chezmoi update  (on other machines)
    ▼
Other managed machines
```

The key point: **this repo and Chezmoi are complementary, not competing**.

- On a machine **without Chezmoi** (work laptop, new server): `bash bootstrap.sh` gives
  you the full environment in one step.
- On a machine **with Chezmoi** (your Mac, Bluefin workstation): Chezmoi handles
  config deployment, bootstrap handles package installation.

---

## What goes into Chezmoi

Only **config files** — the things in `configs/`. Not scripts, not package installs.

| File | In Chezmoi? | Notes |
|---|---|---|
| `~/.tmux.conf.local` | ✅ Template | Clipboard tool varies per OS — see below |
| `~/.config/starship.toml` | ✅ Plain | Identical on all platforms |
| `~/.config/atuin/config.toml` | ✅ Plain | Identical on all platforms |
| `~/.config/ghostty/config` | ✅ Plain | Skipped automatically on Ubuntu Server |
| `~/.config/tmuxinator/*.yml` | ✅ Plain | Identical on all platforms |
| `~/.config/mc/ini` | ✅ Plain | Identical on all platforms |
| `~/.config/nvim/lua/config/options.lua` | ✅ Plain | Our overlay — identical everywhere |
| `~/.config/nvim/lua/config/keymaps.lua` | ✅ Plain | Our overlay — identical everywhere |
| `~/.config/nvim/lua/plugins/extras.lua` | ✅ Plain | Our overlay — identical everywhere |
| `~/.config/nvim/lua/plugins/lang.lua` | ✅ Plain | Our overlay — identical everywhere |
| `~/.zshrc` | ❌ | Too machine-specific; managed by bootstrap append |
| `~/.tmux.conf` | ❌ | Symlink to oh-my-tmux; managed by bootstrap |
| `~/.config/nvim/init.lua` | ❌ | LazyVim boilerplate, not our config |
| `~/.config/nvim/lua/config/lazy.lua` | ❌ | LazyVim boilerplate, not our config |
| `~/.local/share/nvim/` | ❌ | lazy.nvim plugin cache — not config |

---

## The one template: tmux clipboard

Every config is identical across platforms except one line in `~/.tmux.conf.local` —
the extrakto clipboard tool:

| Platform | Value |
|---|---|
| macOS | `pbcopy` |
| Bluefin (Wayland) | `wl-copy` |
| Ubuntu Server (headless) | `tmux` (stays in tmux buffer) |

The template in `configs/tmux/tmux.conf.local.chezmoi.tmpl` uses a single-line
Chezmoi conditional to resolve this at `chezmoi apply` time:

```
set -g @extrakto_clip_tool '{{ if eq .chezmoi.os "darwin" }}pbcopy{{ else if lookPath "wl-copy" }}wl-copy{{ else }}tmux{{ end }}'
```

- `eq .chezmoi.os "darwin"` — true on macOS
- `lookPath "wl-copy"` — true if `wl-copy` is in PATH (Wayland machines)
- fallback — headless/unknown

The plain `configs/tmux/tmux.conf.local` (used by bootstrap without Chezmoi) keeps
`pbcopy` as the default and the bootstrap scripts patch it with `sed` for Linux.

---

## Managed platforms

| Platform | Chezmoi? | Bootstrap? |
|---|---|---|
| macOS | ✅ | ✅ (for packages) |
| Bluefin workstation | ✅ | ✅ (for packages) |
| Ubuntu Server | ❌ (minimal builds) | ✅ only |

Ubuntu Server uses bootstrap only — no Chezmoi. This is intentional. Servers get a
functional terminal environment from bootstrap; you don't need dotfile sync on them.

---

## First-time setup on a managed machine

### Step 1 — Install packages (bootstrap)

Bootstrap only handles packages. Run it first, before Chezmoi.

```bash
# macOS
bash bootstrap_macos.sh

# Bluefin
bash bootstrap_bluefin.sh
```

### Step 2 — Register configs with Chezmoi

```bash
bash install_to_chezmoi.sh
```

This adds all config files to the Chezmoi source directory and installs the
tmux template. It reads from your deployed `~/` — that's why step 1 must run first.

### Step 3 — Push your Chezmoi source

```bash
cd ~/.local/share/chezmoi
git add -A
git commit -m "add turbo-shell configs"
git push
```

---

## Applying to a second machine

On a machine that already has your Chezmoi repo configured:

```bash
# Install packages first
bash /path/to/turbo-shell/bootstrap_<platform>.sh

# Pull and apply latest configs
chezmoi update
```

On a brand-new machine with no Chezmoi setup:

```bash
# Install chezmoi
brew install chezmoi   # or the install script

# Bootstrap packages
bash /path/to/turbo-shell/bootstrap_<platform>.sh

# Initialise Chezmoi from your dotfiles repo and apply
chezmoi init <your-github-username>   # or full repo URL
chezmoi apply
```

---

## Day-to-day workflow

### Updating a config in this repo and pushing it everywhere

```bash
# 1. Edit the config in this repo
nvim configs/nvim/lua/plugins/extras.lua

# 2. Re-deploy to ~/  (packages already installed, just the config changes)
bash bootstrap_<platform>.sh

# 3. Update Chezmoi source to match the new deployed file
bash install_to_chezmoi.sh

# 4. Push to your dotfiles repo
cd ~/.local/share/chezmoi && git add -A && git commit -m "..." && git push

# 5. On other managed machines
chezmoi update
```

### Editing a config directly (without going through this repo)

If you edit a deployed file directly (e.g., `nvim ~/.config/starship.toml`):

```bash
chezmoi re-add ~/.config/starship.toml   # update Chezmoi source to match
```

Then sync back to this repo if you want the change tracked here too:

```bash
cp ~/.config/starship.toml <path-to-repo>/configs/starship/starship.toml
```

### Checking what Chezmoi would change

```bash
chezmoi diff              # shows diff between source and deployed
chezmoi status            # shows which files are out of sync
chezmoi apply --dry-run   # preview apply without making changes
```

---

## Verifying the tmux template

After `chezmoi apply`, verify the clipboard line resolved correctly:

```bash
grep extrakto_clip_tool ~/.tmux.conf.local
```

Expected output:
- macOS: `set -g @extrakto_clip_tool 'pbcopy'`
- Bluefin: `set -g @extrakto_clip_tool 'wl-copy'`

If it shows `tmux` on Bluefin, `wl-copy` isn't in your PATH — install `wl-clipboard`
(see `PLATFORMS.md`).

---

## Adding a new config file to Chezmoi

When you add a new config to this repo in future:

1. Add the file to `configs/<tool>/`
2. Update `bootstrap_macos.sh`, `bootstrap_ubuntu.sh`, and `bootstrap_bluefin.sh`
   to deploy it
3. Run bootstrap to deploy it to `~/`
4. Add one line to `install_to_chezmoi.sh`:
   ```bash
   add_if_exists "$HOME/.config/newtool/config" "~/.config/newtool/config"
   ```
5. Run `bash install_to_chezmoi.sh`

If the new config needs platform-specific content, create a
`configs/<tool>/config.chezmoi.tmpl` alongside the plain version and handle it
in `install_to_chezmoi.sh` the same way tmux is handled.
