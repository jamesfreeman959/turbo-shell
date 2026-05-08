-- Extra plugins on top of LazyVim's defaults
return {

  -- ── Seamless ctrl+h/j/k/l navigation between nvim splits and tmux panes ───
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft", "TmuxNavigateDown",
      "TmuxNavigateUp",   "TmuxNavigateRight",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>",  desc = "Go to left pane" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>",  desc = "Go to lower pane" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>",    desc = "Go to upper pane" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right pane" },
    },
  },

  -- ── Tokyo Night theme — keep in sync with tmux + Ghostty ──────────────────
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        sidebars = "dark",
        floats = "dark",
      },
    },
  },

  -- ── lazygit inside nvim — <leader>gg ──────────────────────────────────────
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>",            desc = "LazyGit" },
      { "<leader>gf", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (current file)" },
    },
  },

  -- ── oil.nvim — edit filesystem like a buffer, open with - ─────────────────
  {
    "stevearc/oil.nvim",
    opts = {
      default_file_explorer = false, -- keep neo-tree as default, oil as extra
      delete_to_trash = true,
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        ["<C-h>"] = false, -- don't conflict with vim-tmux-navigator
        ["<C-l>"] = false,
      },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent dir (oil)" },
    },
  },

  -- ── render-markdown — rich display of .md files (LLM output, docs) ────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown", "norg", "rmd", "org" },
    opts = {
      enabled = true,
      heading = { enabled = true },
      code = { enabled = true, sign = true },
      bullet = { enabled = true },
    },
  },

  -- ── todo-comments — highlight TODO/FIXME/NOTE/HACK/WARN ──────────────────
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      signs = true,
      keywords = {
        TODO  = { icon = " ", color = "info"    },
        FIXME = { icon = " ", color = "error"   },
        HACK  = { icon = " ", color = "warning" },
        WARN  = { icon = " ", color = "warning" },
        NOTE  = { icon = " ", color = "hint"    },
      },
    },
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo comment" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev todo comment" },
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find todos" },
    },
  },

}
