# ─────────────────────────────────────────────────────────────────────────────
# turbo-shell additions
# Appended to ~/.zshrc by bootstrap.sh
# ─────────────────────────────────────────────────────────────────────────────

# ── Mosh: auto-attach to tmux on connect ─────────────────────────────────────
# If this shell was spawned by mosh-server and we're not already inside tmux,
# attach to the 'main' session or create it. Combined with tmux-continuum, your
# workspace is always exactly where you left it.
if [[ -n "$MOSH_SERVER_PID" ]] && command -v tmux >/dev/null 2>&1 && [[ -z "$TMUX" ]]; then
  tmux attach-session -t main 2>/dev/null || tmux new-session -s main
fi

# ── SSH: set window title + rename tmux window ───────────────────────────────
# Replaces the simpler ssh() function previously in this file.
# NOTE: If you have an existing ssh() function earlier in ~/.zshrc, remove it.
#
# This version:
#  1. Parses the destination correctly (strips flags and flag arguments)
#  2. Sets the Ghostty/iTerm2 window title
#  3. Renames the tmux window to the destination hostname
#  4. Restores both on exit (including Ctrl+C)
function ssh() {
  # Extract destination, filtering out flags and their parameters
  local dest
  dest="$(echo "$@" | sed 's/[[:space:]]*\(\(\(-[46AaCfGgKkMNnqsTtVvXxYy]\)\|\(-[^[:space:]]*\([[:space:]]\+[^[:space:]]*\)\?\)\)[[:space:]]*\)*[[:space:]]\+\([^-][^[:space:]]*\).*/\6/')"
  [[ -z "$dest" ]] && dest="${@##*@}" && dest="${dest%% *}"

  # Set window/tab title in terminal emulator
  print -Pn "\e]0;SSH: $dest\a"

  if [[ -n "$TMUX" ]]; then
    tmux rename-window "ssh:$dest"
    trap 'tmux set-window-option automatic-rename on >/dev/null 2>&1
          print -Pn "\e]0;Terminal\a"' SIGINT SIGTERM EXIT
    command ssh "$@"
    local exit_code=$?
    trap - SIGINT SIGTERM EXIT
    tmux set-window-option automatic-rename on >/dev/null 2>&1
  else
    command ssh "$@"
    local exit_code=$?
  fi

  print -Pn "\e]0;Terminal\a"
  return $exit_code
}

# ── atuin — better shell history (replaces ctrl+r) ───────────────────────────
# Self-hosted sync: configure server URL in ~/.config/atuin/config.toml first.
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
  # --disable-up-arrow: up-arrow still does normal zsh history search.
  # ctrl+r opens atuin's full search UI across all machines.
fi

# ── zoxide — smarter cd ───────────────────────────────────────────────────────
# z <partial-path>  → jump to most frecent match
# zi               → interactive FZF picker over frecency list
# cd still works normally; zoxide learns from it.
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ── yazi — TUI file manager with cd-on-exit ───────────────────────────────────
# Use 'y' instead of 'yazi' directly to cd into the dir you navigate to.
function y() {
  local tmp
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [[ -n "$cwd" ]] && [[ "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# ── Linux compatibility shims ─────────────────────────────────────────────────
# Ubuntu installs bat as 'batcat' and fd as 'fdfind' to avoid package name
# conflicts. The bootstrap creates symlinks in ~/.local/bin, but these guards
# catch any machine where that hasn't been done yet.
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
fi
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

# ── lsd — better ls (true drop-in: ls -ltr and all traditional flags work) ───
if command -v lsd >/dev/null 2>&1; then
  alias ls='lsd'
  alias ll='lsd -la --header --git'
  alias la='lsd -a'
  alias lt='lsd --tree --depth 3'
  alias l='lsd -l --git'
fi

# ── bat — better cat ──────────────────────────────────────────────────────────
if command -v bat >/dev/null 2>&1; then
  # 'ansi' defers to the terminal's own colour palette rather than baking in
  # background colours — avoids contrast issues when the theme doesn't match exactly.
  # (tokyonight_night is still installed in bat's theme cache for delta to use.)
  export BAT_THEME="ansi"
  alias cat='bat --paging=never'
  alias bp='bat --plain'
  # Use bat for man pages (colourised)
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# ── delta — better git diffs ─────────────────────────────────────────────────
# Git is configured to use delta as pager by bootstrap.sh (in ~/.gitconfig).
# The alias below is for diffing arbitrary files outside git.
if command -v delta >/dev/null 2>&1; then
  alias ddiff='delta'
fi

# ── difftastic — semantic side-by-side diff ───────────────────────────────────
# git dft           → semantic diff of working tree
# git dft HEAD~1    → diff against a commit
# difft file1 file2 → diff arbitrary files
if command -v difft >/dev/null 2>&1; then
  export DFT_DISPLAY=side-by-side-show-both
fi

# ── lazygit ───────────────────────────────────────────────────────────────────
alias lg='lazygit'

# ── ripgrep / fd ──────────────────────────────────────────────────────────────
# FZF: use fd for file finding (respects .gitignore, much faster)
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# FZF display options — preview files with bat, preview dirs with lsd
export FZF_DEFAULT_OPTS="
  --height=50%
  --layout=reverse
  --border=rounded
  --info=inline
  --color=bg+:#24283b,bg:#1a1b26,spinner:#7dcfff,hl:#f7768e
  --color=fg:#c0caf5,header:#f7768e,info:#9ece6a,pointer:#7dcfff
  --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#f7768e
  --preview-window=right:60%:wrap
"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers {} 2>/dev/null || lsd --tree {} 2>/dev/null'"
export FZF_ALT_C_OPTS="--preview 'lsd --tree --depth 2 {} 2>/dev/null'"

# ── btop ─────────────────────────────────────────────────────────────────────
alias top='btop'

# ── helpme — fzf-driven cheatsheet viewer (requires glow) ────────────────────
CHEATSHEET_DIR="$HOME/.local/share/cheatsheets"
function helpme() {
  if ! command -v glow >/dev/null 2>&1; then
    echo "glow not installed — run: brew install glow" >&2; return 1
  fi
  [[ ! -d "$CHEATSHEET_DIR" ]] && { echo "No cheatsheets at $CHEATSHEET_DIR" >&2; return 1; }
  if [[ -n "$1" ]]; then
    local file="$CHEATSHEET_DIR/$1.md"
    [[ ! -f "$file" ]] && file=$(ls "$CHEATSHEET_DIR"/*"$1"*.md 2>/dev/null | head -1)
    [[ -z "$file" ]] && { echo "No cheatsheet matching '$1'" >&2; return 1; }
    glow -p "$file"
  else
    local chosen
    chosen=$(ls "$CHEATSHEET_DIR"/*.md 2>/dev/null \
      | xargs -I{} basename {} .md \
      | fzf --prompt="helpme> " --preview="glow $CHEATSHEET_DIR/{}.md")
    [[ -n "$chosen" ]] && glow -p "$CHEATSHEET_DIR/$chosen.md"
  fi
}

# ── tmux bell on long commands ───────────────────────────────────────────────
# Rings the terminal bell when a command takes longer than _BELL_THRESHOLD
# seconds. Inside tmux, this lights up the 🔔 on the window tab so you know
# the command finished while you were in another window.
_BELL_THRESHOLD=10
_bell_cmd_start=0
autoload -Uz add-zsh-hook
function _bell_preexec() { _bell_cmd_start=$SECONDS }
function _bell_precmd() {
  local elapsed=$(( SECONDS - _bell_cmd_start ))
  [[ $_bell_cmd_start -gt 0 && $elapsed -ge $_BELL_THRESHOLD ]] && print -n '\a'
  _bell_cmd_start=0
}
add-zsh-hook preexec _bell_preexec
add-zsh-hook precmd  _bell_precmd

# ── tmuxinator shortcuts ──────────────────────────────────────────────────────
alias mux='tmuxinator'
alias muxs='tmuxinator start'
alias muxe='tmuxinator edit'
alias muxl='tmuxinator list'
