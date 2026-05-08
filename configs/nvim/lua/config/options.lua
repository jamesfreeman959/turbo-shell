-- Options loaded after LazyVim defaults
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
local opt = vim.opt

-- Line numbers: show absolute on current line, relative on others
opt.relativenumber = true

-- Keep cursor 8 lines from top/bottom edges when scrolling
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Indentation: 2-space soft tabs (LazyVim default, but explicit here)
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

-- Open splits on the right and below (more natural)
opt.splitright = true
opt.splitbelow = true

-- Persistent undo — survives nvim restarts
opt.undofile = true
opt.undolevels = 10000

-- Case-insensitive search unless uppercase is used
opt.ignorecase = true
opt.smartcase = true

-- Show substitution preview as you type (live :s/foo/bar)
opt.inccommand = "nosplit"

-- British English spell checking (off by default, toggle with <leader>us)
opt.spelllang = { "en_gb" }

-- Highlight the line the cursor is on
opt.cursorline = true

-- Wider sign column so git signs don't cause layout shifts
opt.signcolumn = "yes:1"

-- Fold using treesitter expressions (LazyVim configures this, but ensure it)
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldenable = false  -- start with all folds open

-- System clipboard — yanks go straight to macOS clipboard
opt.clipboard = "unnamedplus"

-- Show invisible chars (tabs, trailing spaces, nbsp)
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Keep at least one line of context around folds
opt.foldlevel = 99

-- Faster update for git signs and diagnostics
opt.updatetime = 200
