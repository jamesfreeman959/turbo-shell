# Neovim / LazyVim Cheat Sheet

> This covers the 20% of bindings you'll use 80% of the time.
> Press **`<Space>`** and wait 500ms — which-key shows every available binding.

---

## The Golden Rule: Modes

| Mode | How to enter | What it does |
|---|---|---|
| **Normal** | `Esc` or `Ctrl+c` | Navigate, command everything. Default mode. |
| **Insert** | `i` (before cursor), `a` (after), `o` (new line below), `O` (new line above) | Type text |
| **Visual** | `v` (char), `V` (line), `Ctrl+v` (block) | Select text |
| **Command** | `:` | Run Ex commands (`:w`, `:q`, `:s/foo/bar/g`) |

**Rule:** When in doubt, press `Esc`. You're always safe in Normal mode.

---

## Navigation (Normal mode)

| Key | Action |
|---|---|
| `h j k l` | Left / Down / Up / Right (or just use arrow keys to start) |
| `w` / `b` | Jump forward / backward by word |
| `0` / `$` | Start / end of line |
| `gg` / `G` | Top / bottom of file |
| `Ctrl+d` / `Ctrl+u` | Half-page down / up |
| `{` / `}` | Jump between blank-line-separated paragraphs |
| `%` | Jump to matching bracket |
| `*` | Search for word under cursor |
| `gd` | Go to **d**efinition (LSP) |
| `gr` | Show **r**eferences (LSP) |
| `K` | Hover docs for symbol under cursor (LSP) |
| `Ctrl+o` | Jump back in location history |
| `Ctrl+i` | Jump forward in location history |

### Pane / split navigation (works across tmux too)
| Key | Action |
|---|---|
| `Ctrl+h/j/k/l` | Move to left / down / up / right pane (nvim splits *and* tmux panes) |

---

## Neo-tree (file explorer sidebar)

Neo-tree is a Neovim plugin bundled with LazyVim — not a standalone app. When you start Neovim with `nvim .` (a directory), LazyVim opens neo-tree automatically as a left sidebar.

Pressing `Esc` in Normal mode can move focus away from it. To get it back:

| Key | Action |
|---|---|
| `<Space>e` | Toggle neo-tree open / closed |
| `Ctrl+h` | Move cursor into the neo-tree panel (move left) |

**Inside neo-tree:**

| Key | Action |
|---|---|
| `Enter` | Open file / expand directory |
| `a` | Create file (append `/` to create a directory) |
| `d` | Delete |
| `r` | Rename |
| `y` | Copy path |
| `q` | Close neo-tree |
| `?` | Show all neo-tree bindings |

---

## The `<Space>` Leader Menu

Press `<Space>` and wait — every option is labelled. Key groups:

| Prefix | Group |
|---|---|
| `<Space>f` | **F**ind (telescope) |
| `<Space>g` | **G**it |
| `<Space>b` | **B**uffers |
| `<Space>c` | **C**ode / LSP |
| `<Space>x` | Diagnostics / todo list |
| `<Space>u` | **U**I toggles (dark/light, spell, wrap…) |
| `<Space>w` | **W**indow management |

### Most-used leader bindings

| Key | Action |
|---|---|
| `<Space><Space>` | Find files (telescope, respects .gitignore) |
| `<Space>/` | Grep in project (live ripgrep) |
| `<Space>e` | File explorer (neo-tree toggle) |
| `-` | Open parent directory (oil.nvim — edit it like a buffer) |
| `<Space>gg` | Open lazygit |
| `<Space>gf` | lazygit for current file's history |
| `<Space>w` | Save file |
| `<Space>bd` | Delete current buffer (close tab) |
| `<Space>bo` | Close all *other* buffers |
| `<Space>ca` | Code **a**ction (fix, refactor, etc.) |
| `<Space>cr` | **R**ename symbol (LSP) |
| `<Space>cf` | **F**ormat file |
| `<Space>cs` | **S**ymbols outline (aerial) |
| `<Space>fy` | Open yazi at current file's dir |
| `<Space>ft` | Find TODO/FIXME comments |
| `<Space>xx` | Show diagnostics (errors/warnings) |
| `<Space>us` | Toggle spell check |

---

## Telescope (fuzzy finder)

Once the picker is open:

| Key | Action |
|---|---|
| `Ctrl+p` / `Ctrl+n` | Move up / down in results |
| `Enter` | Open selection |
| `Ctrl+v` | Open in vertical split |
| `Ctrl+x` | Open in horizontal split |
| `Ctrl+t` | Open in new tab |
| `Ctrl+q` | Send results to quickfix list |
| `Esc` | Close picker |

---

## Editing

| Key | Action |
|---|---|
| `dd` | Delete line (goes to register — use `x` to truly delete) |
| `yy` | Yank (copy) line |
| `p` / `P` | Paste after / before |
| `u` / `Ctrl+r` | Undo / redo |
| `ciw` | **C**hange **i**nner **w**ord (delete word and enter insert) |
| `di"` | **D**elete **i**nside quotes |
| `gsa"` | **Add** surrounding double quotes (mini.surround) |
| `gsd"` | **Delete** surrounding double quotes |
| `gsr"'` | **Replace** `"` surrounding with `'` |
| `Alt+j` / `Alt+k` | Move current line (or selection) down / up |
| `gc` + motion | Toggle comment (e.g. `gcc` comments current line) |

### Search and replace
```
:s/old/new/g        replace in current line
:%s/old/new/g       replace in entire file
:%s/old/new/gc      replace with confirmation
```
For project-wide replace: `<Space>/` → search → `Ctrl+q` to send to quickfix → `:cfdo s/old/new/g | update`

---

## Git (lazygit + gitsigns)

| Key | Action |
|---|---|
| `<Space>gg` | Open lazygit (full TUI) |
| `]h` / `[h` | Next / prev git hunk |
| `<Space>ghs` | Stage hunk under cursor |
| `<Space>ghr` | Reset hunk under cursor |
| `<Space>ghp` | Preview hunk |
| `<Space>gb` | Git blame for current line |

**In lazygit:** `?` shows all bindings. Common: `s` stage, `c` commit, `p` push, `P` pull, `q` quit.

---

## LSP (code intelligence)

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Find references |
| `gI` | Go to implementation |
| `K` | Hover documentation |
| `<Space>ca` | Code actions |
| `<Space>cr` | Rename symbol |
| `<Space>cf` | Format buffer |
| `]d` / `[d` | Next / prev diagnostic |
| `<Space>cd` | Show diagnostic detail |

---

## Buffers and windows

| Key | Action |
|---|---|
| `]b` / `[b` | Next / prev buffer |
| `<Space>bd` | Delete buffer |
| `<Space>|` | Vertical split |
| `<Space>_` | Horizontal split |
| `Ctrl+w =` | Equalise split sizes |
| `Ctrl+w o` | Close all splits except current |

---

## Useful `:` commands

```
:w              save
:q              quit
:wq             save and quit
:q!             quit without saving
:e filename     open file
:vs filename    open file in vertical split
:terminal       open terminal in split
:Mason          manage language servers
:Lazy           manage plugins
:checkhealth    diagnose nvim setup
```

---

## Getting unstuck

- **Stuck in a mode?** → Press `Esc` (twice if needed)
- **Accidentally hit something?** → `u` to undo
- **Don't know what a key does?** → `:help <key>` or press the key and let which-key show you
- **Want to see all bindings?** → `<Space>` and browse the which-key tree
