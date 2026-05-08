# New Tools Reference

## What replaces what

| Old habit | New tool | Why |
|---|---|---|
| `ssh` + typing `tmux attach` | automatic on Mosh connect | `zshrc` detects `MOSH_SERVER_PID` |
| `iTerm2` | **Ghostty** | Native Metal rendering, simpler config, better Mosh compatibility |
| `cd` | **zoxide** | Learns your directories; `z proj` beats `cd ~/Development/project` |
| `Ctrl+r` history | **atuin** | Syncs across machines, stores exit codes & duration, fuzzy search |
| `ls` / `ls -la` | **lsd** | Icons, git status, all traditional flags work (`ls -ltr` etc.) |
| `cat` | **bat** | Syntax highlighting, line numbers, git diff markers |
| `git diff` (plain) | **delta** | Syntax-highlighted, side-by-side line diffs — automatic as git pager |
| `diff file1 file2` | **difftastic** | Understands code structure — diffs by meaning not just lines |
| `top` / `htop` | **btop** | Full TUI with graphs for CPU, memory, network, disk |
| `vim` | **Neovim + LazyVim** | LSP, treesitter, telescope, which-key — full IDE in the terminal |
| fpp / PathPicker | **yazi** | Full TUI file manager with preview; shell `cd`s to where you navigate |

---

## Tool reference

| Tool | Purpose | Key commands |
|---|---|---|
| **ghostty** | Terminal emulator | Config: `~/.config/ghostty/config` |
| **zoxide** | Frecency-based `cd` | `z <partial>` jump · `zi` FZF picker · `cd` still works |
| **atuin** | Shell history with sync | `Ctrl+r` search UI · `atuin import auto` · `atuin sync` |
| **yazi** | TUI file manager | `y` (aliased, cd-on-exit) · `q` quit · arrow keys navigate · `Enter` open |
| **lsd** | Modern `ls` | `ll` long · `la` all · `lt` tree · `ls -ltr` and all traditional flags work |
| **bat** | Syntax-highlighted `cat` | `cat <file>` (aliased) · `bat -l json <file>` force language |
| **delta** | Git diff pager | Automatic — just use `git diff`, `git log -p`, `git show` |
| **difftastic** | Semantic side-by-side diff | `git dft` in repo · `difft file1 file2` for arbitrary files |
| **lazygit** | Full TUI git client | `lg` to open · `?` for help inside · `q` quit |
| **btop** | System monitor | `top` (aliased) · mouse-driven · `q` quit |
| **ripgrep** | Fast recursive grep | `rg "pattern"` · `rg "pattern" src/` · respects `.gitignore` |
| **fd** | Fast `find` replacement | `fd <name>` · `fd -e py` by extension · respects `.gitignore` |
| **sesh** | tmux session manager | Used via `Ctrl+a T` in tmux — not invoked directly |
| **tmuxinator** | Session layout templates | `mux start main` · `mux start llm` · `mux edit main` to customise |
| **fzf** | Fuzzy finder (enhanced) | `Ctrl+r` (atuin) · `Ctrl+t` files · `Alt+c` cd into dir |

---

## Quick examples

```bash
# Jump to a project you've visited before
z turbo          # → <wherever you cloned turbo-shell>

# Find a file you half-remember
fd config        # lists all files named 'config' in the tree

# Search file contents across the project  
rg "ssh_only"    # shows every file + line containing that string

# See a file with syntax highlighting
cat ~/.zshrc     # bat renders it with colour and line numbers

# Semantic diff — "what actually changed logically?"
git dft HEAD~3

# Start your standard workspace
mux start main   # opens nvim + shell + lazygit + btop

# Open file manager and land in the directory you browse to
y                # press q in yazi → your shell is now in that directory
```
