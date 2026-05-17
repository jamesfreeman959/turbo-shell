# Midnight Commander Cheat Sheet

> Focused on file selection and operations — the things NC muscle memory used to handle.
> **Mac note:** if F1–F10 trigger media keys, go to System Settings → Keyboard → enable "Use F1, F2 etc. as standard function keys", or press **Fn+F1** etc.

---

## What you're looking at

```
┌─────── Left panel ──────┐ ┌──────── Right panel ──────┐
│ Name        Size  Date  │ │ Name         Size  Date   │
│ ..                      │ │ ..                        │
│ Documents   DIR         │ │ archive.tar  1.2M         │
│▌project     DIR        ▐│ │ notes.txt    4K           │
└─────────────────────────┘ └───────────────────────────┘
[ shell command line at the bottom ]
[ F1 Help  F3 View  F4 Edit  F5 Copy  F6 Move  F7 Mkdir  F8 Del  F10 Quit ]
```

Operations act on the **marked set** if files are marked, otherwise on the **file under the cursor**. The destination is always the **other panel's directory** unless you change it in the dialog.

---

## Panel switching and layout

| Key | Action |
|---|---|
| `Tab` | Switch active panel |
| `Ctrl+U` | Swap left/right panels |
| `Ctrl+O` | Toggle shell overlay — hides panels, drops you to a full shell. Press again to return. Invaluable for running git, grep, etc. without quitting MC. |
| `Ctrl+R` | Rescan / refresh current panel |
| `Alt+T` | Cycle panel view mode (full / brief / long) |
| `Alt+I` | Mirror: show the same directory in the other panel |
| `Alt+.` | Toggle hidden (dot) files |

---

## Navigation

| Key | Action |
|---|---|
| Arrow keys | Move cursor |
| `Enter` | Open directory / run file |
| `Backspace` | Go to parent directory |
| `Ctrl+\` | Directory hotlist — your saved favourite paths (add with `Ctrl+\` → `Add`) |
| `Alt+H` | Browse this panel's directory history |
| `Ctrl+S` then type | Quick search: jump to the first file matching what you type. `Esc` to cancel. |
| Type a path + Enter (in the command bar) | Navigate the active panel to any path — just click the command bar at the bottom and type `cd ~/wherever` |

**To jump to a known path quickly:** use `Ctrl+\` (hotlist) for saved directories, or click the command bar and type the path directly.

---

## Selecting files — the Mac problem

The classic Norton Commander used the **Insert** key to mark files one by one. Apple laptops don't have one.

**The Mac alternatives:**

| Key | Action |
|---|---|
| `Ctrl+T` | Mark / unmark file under cursor, move down — the Insert key replacement in modern MC |
| `+` | **Select by pattern** — dialog to mark files matching a glob (e.g. `*.jpg`, `report*`). This is often faster than marking one by one. |
| `-` | **Deselect by pattern** — reverse of the above |
| `*` | **Invert selection** — marks everything unmarked, unmarks everything marked. Useful for "select all": `*` when nothing is marked. |

> If `Ctrl+T` doesn't work on your build: **F9 → File → Tag File** does the same thing via menu.

Marked files show in a different colour (yellow in the nc-classic skin). The count appears in the panel header.

---

## File operations

These operate on the **marked set** if anything is marked, otherwise on the cursor file.

| Key | Action |
|---|---|
| `F3` | View file (read-only, with syntax highlight in newer MC) |
| `F4` | Edit file — opens in `$EDITOR`, which is **nvim** in this setup |
| `F5` | Copy to other panel's path (dialog lets you change destination) |
| `F6` | Move / rename — to other panel's path, or rename if you clear the path |
| `F7` | Create new directory |
| `F8` | Delete (confirmation dialog) |
| `F10` | Quit |

**Variations:**

| Key | Action |
|---|---|
| `Shift+F5` | Copy *and* rename — copies to the **same** directory under a new name |
| `Shift+F6` | Rename in place — renames in the current directory without moving |

**Typical copy/move workflow:**
1. Navigate left panel to source directory
2. Navigate right panel to destination directory
3. Mark the files you want (`Ctrl+T` / `+`)
4. `F5` (copy) or `F6` (move) — destination is pre-filled as the other panel's path
5. Confirm

---

## Command line integration

The bar at the bottom is a real shell command line. Files and paths from the panels can be injected into it:

| Key | Action |
|---|---|
| `Ctrl+Enter` | Insert the filename under cursor into the command line |
| `Ctrl+Shift+Enter` | Insert the **full path** of the file under cursor |
| `Enter` (in command bar) | Run the typed command, then return to panels |
| `Ctrl+O` | Toggle full shell — run multiple commands, then come back |

---

## Searching for files

| Key / menu | Action |
|---|---|
| `Ctrl+S` | Quick search within current panel (type to jump) |
| `F9 → Command → Find File` | Full recursive search with name pattern and content grep. Results panel lets you navigate and act on found files. |

---

## The escape hatch

Forgotten a key? **Press `F9`** to open the menu bar. Everything in MC is reachable from there — Left, File, Command, Options, Right. Worth a browse once to know what exists.

---

## Tips

**Use both panels like NC intended.** Navigate to your source on one side, destination on the other, then `F5`/`F6`. It's faster than typing paths.

**`Ctrl+O` is your friend.** You don't need to quit MC to run shell commands. Toggle to the shell, run `git status`, `grep`, whatever, then toggle back. MC is still exactly where you left it.

**`F4` opens nvim.** Treat MC as a fuzzy-free file picker when you need to browse to something you'd struggle to find by path alone — navigate to it, `F4` to open.

**Pattern select beats one-by-one.** Instead of `Ctrl+T` twelve times, use `+` with a glob. `*.png` selects all PNGs in the panel instantly.

**Rename with `Shift+F6`.** This is the quickest way to rename a single file — no need to mark it first, just cursor over it and `Shift+F6`.

**Add directories to the hotlist.** `Ctrl+\` → Add. Your frequently-used project paths, `~/Downloads`, wherever you go often. It's the closest thing to bookmarks.
