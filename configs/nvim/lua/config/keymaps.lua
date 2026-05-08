-- Keymaps loaded on VeryLazy event, after LazyVim defaults
-- LazyVim defaults: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
local map = vim.keymap.set

-- ── File operations ───────────────────────────────────────────────────────────
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<leader>W", "<cmd>wa<cr>", { desc = "Save all files" })

-- ── Move lines up/down (Alt+j/k) ─────────────────────────────────────────────
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- ── Search ────────────────────────────────────────────────────────────────────
-- Clear search highlights on Escape (LazyVim also binds this, kept explicit)
map("n", "<esc>", "<cmd>nohlsearch<cr><esc>", { desc = "Clear search highlight" })

-- ── Yazi file manager ─────────────────────────────────────────────────────────
-- Opens yazi floating window via snacks.nvim integration (see extras.lua)
map("n", "<leader>fy", function()
  Snacks.terminal("yazi " .. vim.fn.expand("%:p:h"), {
    win = { style = "float", height = 0.8, width = 0.9 },
  })
end, { desc = "Yazi (file dir)" })

map("n", "<leader>fY", function()
  Snacks.terminal("yazi " .. vim.fn.getcwd(), {
    win = { style = "float", height = 0.8, width = 0.9 },
  })
end, { desc = "Yazi (cwd)" })

-- ── Buffer navigation ─────────────────────────────────────────────────────────
-- LazyVim has ]b/[b; these add a quick close-others shortcut
map("n", "<leader>bo", "<cmd>%bd|e#|bd#<cr>", { desc = "Close other buffers" })

-- ── Quickfix / location list ─────────────────────────────────────────────────
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Open quickfix list" })
map("n", "[q", "<cmd>cprev<cr>", { desc = "Prev quickfix item" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix item" })

-- ── Splits (mirrors tmux conventions) ────────────────────────────────────────
map("n", "<leader>|", "<cmd>vs<cr>", { desc = "Vertical split" })
map("n", "<leader>_", "<cmd>sp<cr>", { desc = "Horizontal split" })

-- ── Paste without losing register ────────────────────────────────────────────
-- In visual mode, paste without overwriting the unnamed register
map("v", "p", '"_dP', { desc = "Paste without yanking" })
