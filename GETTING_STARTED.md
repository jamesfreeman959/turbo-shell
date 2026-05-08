# Getting Started

## 1. Run the bootstrap

```bash
cd turbo-shell
bash bootstrap.sh
```

This installs all packages, deploys configs, and appends shell additions to `~/.zshrc`. Existing configs are backed up to `~/.config_backup_<timestamp>` before being replaced.

---

## 2. Manual steps (required, in order)

### Remove the old SSH function from `~/.zshrc`

The additions block includes an improved `ssh()` function. The old one (around lines 16–32 of your original `~/.zshrc`) needs to go, otherwise the new one is shadowed.

Open `~/.zshrc`, find and delete the block that looks like this:

```zsh
# SSH wrapper that sets window title
function ssh() {
  ...
}
```

### Reload your shell

```bash
exec zsh
```

### Install tmux plugins

oh-my-tmux keeps `Ctrl+b` as the primary prefix and adds `Ctrl+a` as a secondary
(GNU Screen-compatible) prefix. Both work for all key bindings.

The bootstrap reloads the config into any running tmux server automatically. If for
any reason the config isn't active, reload it manually:

```bash
tmux source-file ~/.tmux.conf
```

Then attach to (or create) a session — you must be **inside** tmux for prefix keys to work:

```bash
tmux new -s main   # or: tmux attach
```

Inside the session, install plugins by pressing `Ctrl+a` (or `Ctrl+b`) followed by
capital `I`. You'll see plugins downloading in a split at the bottom. Press `Enter`
when it finishes. You only need to do this once — `tmux-continuum` keeps everything
updated after that.

### First Neovim launch

```bash
nvim
```

LazyVim will bootstrap itself and install all plugins. This takes 1–2 minutes on first run. When the plugin list stops scrolling, press `q` to dismiss it, then run:

```
:Mason
```

Press `U` to install/update all language servers. Alternatively, just open a file of the relevant type (`.py`, `.yaml`, etc.) and LazyVim will auto-install the right server on first use.

### Switch to Ghostty

Open **Ghostty.app** — the config is already in place. If the Tokyo Night theme doesn't load, find the correct name with:

```bash
ghostty +list-themes | grep -i tokyo
```

Then update `~/.config/ghostty/config` and change the `theme =` line.

### Configure atuin sync (when ready)

When you've spun up your self-hosted atuin server:

```bash
# 1. Set your server URL
nvim ~/.config/atuin/config.toml
# Change: sync_address = "https://ATUIN_SERVER_URL_PLACEHOLDER"

# 2. Import your existing zsh history into atuin's local database
atuin import auto

# 3. Register on your self-hosted server
atuin register -u <username> -e <email>

# 4. Push your history up
atuin sync
```

On each additional machine, skip `register` and use `atuin login -u <username>` instead.

---

## 3. New tools quick reference

### Shell

| Command | What it does |
|---|---|
| `z <partial>` | Jump to the most frecent matching directory |
| `zi` | Open FZF picker over your frecency list |
| `y` | Open yazi file manager — your shell `cd`s to wherever you navigate to on exit |
| `ll` | `lsd` long list with icons, git status, column headers |
| `lt` | `lsd` tree view, 3 levels deep |
| `lg` | Open lazygit |
| `cat <file>` | `bat` — syntax highlighted, line numbers |
| `top` | `btop` — better system monitor |
| `mux start main` | Start your main tmuxinator session (nvim + shell + ops) |
| `mux start llm` | Start your LLM session (claude + scratch) |
| `ctrl+r` | atuin history search across all machines |
| `up arrow` | Normal zsh history (session only, less surprising) |

### Git diffs

| Command | Use it for |
|---|---|
| `git diff` | Everyday line-by-line diffs — rendered by delta (syntax highlighted, side-by-side) |
| `git dft` | Semantic diffs — difftastic understands code structure, great for reviewing refactors |
| `git dft HEAD~1` | Semantic diff against a specific commit |

### tmux

| Keys | What it does |
|---|---|
| `Ctrl+a T` | FZF session/directory switcher (sesh) — jump to any session or zoxide-known directory |
| `Ctrl+a Tab` | extrakto — fuzzy-grab any text, path, or URL visible in the pane |
| `Ctrl+a \` | tmux-menus help system |
| `Ctrl+a I` | Install / update plugins |
| `Ctrl+a d` | Detach (session keeps running) |
| `Ctrl+a $` | Rename session |
| `Ctrl+a ,` | Rename window |
| `Ctrl+a |` | Split pane vertically |
| `Ctrl+a -` | Split pane horizontally |
| `Ctrl+a z` | Zoom current pane (toggle fullscreen) |
| `Ctrl+a [` | Enter scroll/copy mode (or just use the mouse) |
| `Alt+1–5` | Switch directly to window 1–5 (no prefix needed) |
| `F12` | Toggle outer tmux passthrough (for nested tmux sessions) |

### Neovim

> The full reference is in `NEOVIM_CHEATSHEET.md`. These are the ones to learn first.

| Keys | What it does |
|---|---|
| `Space` (wait 500ms) | which-key — every binding, labelled, browseable |
| `Ctrl+h/j/k/l` | Move between nvim splits **and** tmux panes seamlessly |
| `Space Space` | Find files (telescope) |
| `Space /` | Live grep across project |
| `Space e` | Toggle file explorer |
| `-` | Open parent directory in oil.nvim (edit filesystem like a buffer) |
| `Space g g` | Open lazygit |
| `Space f y` | Open yazi at current file's directory |
| `gd` | Go to definition (LSP) |
| `K` | Hover docs (LSP) |
| `Space c a` | Code actions |
| `Space c r` | Rename symbol |
| `]d` / `[d` | Next / prev diagnostic |
| `Space u s` | Toggle spell check |

---

## 4. Starting a session

After connecting via Mosh, tmux attaches automatically. If you want to start fresh:

```bash
mux start main        # nvim + shell + lazygit/btop
mux start llm         # claude + scratch
```

To switch between running sessions from inside tmux: `Ctrl+a T`

---

## 5. File locations

| Config | Path |
|---|---|
| Ghostty | `~/.config/ghostty/config` |
| tmux | `~/.tmux.conf.local` |
| Neovim | `~/.config/nvim/` |
| Starship | `~/.config/starship.toml` |
| atuin | `~/.config/atuin/config.toml` |
| tmuxinator sessions | `~/.config/tmuxinator/*.yml` |
| This repo | `<path-to-repo>/` |
