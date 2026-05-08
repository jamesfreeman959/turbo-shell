# tmux Cheat Sheet

**Prefix:** `Ctrl+a`  &nbsp;|&nbsp; Written as `^a` below for brevity

---

## Sessions

| Keys | Action |
|---|---|
| `^a T` | FZF session/directory switcher (sesh) |
| `^a d` | Detach — session keeps running |
| `^a $` | Rename current session |
| `^a s` | List sessions (interactive) |
| `tmux new -s name` | New named session (from shell) |
| `tmux attach -t name` | Attach to named session (from shell) |
| `mux start main` | Start tmuxinator `main` template |
| `mux start llm` | Start tmuxinator `llm` template |

## Tmuxinator

Tmuxinator lets you define a full tmux layout — windows, pane splits, and startup commands — in a YAML file, then launch the whole thing with one command.

| Command | Action |
|---|---|
| `mux start main` | Create the `main` session (nvim + shell + ops) — only useful if it doesn't already exist |
| `mux start llm` | Create the `llm` session (claude + scratch) |
| `mux start main -n myproject` | Create a fresh `main` layout named `myproject` |
| `mux start main root=~/path` | Create `main` session rooted at a different directory |
| `mux list` | List available templates |
| `mux edit main` | Edit the `main` template in `$EDITOR` |

Templates live at `~/.config/tmuxinator/*.yml`.

**`main` session layout:**
- **editor** — `nvim .` on the left (60%), shell on the right (40%)
- **shell** — plain shell in project root
- **ops** — lazygit and btop side by side

**Neo-tree** (the file sidebar inside Neovim) is opened automatically when `nvim .` starts. If it disappears:

| Keys | Action |
|---|---|
| `Space e` | Toggle neo-tree open/closed |
| `Ctrl+h` | Move cursor into the neo-tree panel |
| `Enter` | Open file under cursor |
| `a` / `d` / `r` | Create / delete / rename |
| `?` | Show all neo-tree bindings |

## Windows (tabs)

| Keys | Action |
|---|---|
| `^a c` | New window |
| `^a ,` | Rename window |
| `^a &` | Kill window |
| `^a n` / `^a p` | Next / previous window |
| `^a 0–9` | Go to window by number |
| `Alt+1–5` | Go to window 1–5 (no prefix needed) |

## Panes (splits)

| Keys | Action |
|---|---|
| `^a \|` | Split vertically (new pane right) |
| `^a -` | Split horizontally (new pane below) |
| `^a x` | Kill pane |
| `^a z` | Zoom pane to full window (toggle) |
| `^a {` / `^a }` | Swap pane left / right |
| `^a <` / `^a >` | Swap pane with prev / next |
| `^a H/J/K/L` | Resize pane (hold to repeat) |
| `Ctrl+h/j/k/l` | Move between panes **and nvim splits** |

## Copy mode & scrollback

| Keys | Action |
|---|---|
| `^a [` | Enter copy mode (scroll with arrow keys or mouse) |
| `q` / `Esc` | Exit copy mode |
| `Space` | Start selection (in copy mode) |
| `Enter` | Copy selection to clipboard |
| `^a ]` | Paste from tmux buffer |
| Mouse scroll | Scroll without entering copy mode |

## Plugins

| Keys | Action |
|---|---|
| `^a Tab` | **extrakto** — fuzzy-grab text, path, or URL from pane |
| `^a \` | **tmux-menus** — full interactive help/action menu |
| `^a I` | Install / update plugins (TPM) |
| `^a U` | Update plugins (TPM) |

## Misc

| Keys | Action |
|---|---|
| `^a r` | Reload tmux config |
| `^a :` | Enter command mode |
| `^a ?` | List all key bindings |
| `^a m` | Toggle mouse mode |
| `F12` | Toggle outer tmux passthrough (for nested sessions — see below) |

## Running `mux` inside tmux / nested sessions

`mux start <template>` is for **creating a new session** from a template. If a session with that name already exists, tmuxinator does nothing useful — no nesting, but no switch either.

- To **start a fresh layout** for a new project, give it a different name:
  ```
  mux start main -n myproject
  ```
- To **switch to an existing session**, use `^a T` (sesh picker) or `^a s` (session list).

There is no nested tmux — tmuxinator creates a new session on the same tmux server, it does not spawn a new tmux inside a pane.

**Genuine nesting** only happens when you SSH or Mosh into a remote machine that also runs tmux. In that case the outer tmux intercepts all prefix keys before the inner one sees them.

`F12` toggles an input passthrough mode that suspends the outer prefix, letting keystrokes reach the inner tmux session normally. Press `F12` again to resume normal outer-tmux control.

---

> **Copy mode vi keys** (if you use vi mode): `v` select, `y` yank, `/` search
