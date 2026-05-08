-- LazyVim language extras
-- These import pre-configured plugin sets for each language.
-- Add/remove entries as needed. Full list:
-- https://www.lazyvim.org/extras
return {
  { import = "lazyvim.plugins.extras.lang.markdown" }, -- markdown preview + editing
  { import = "lazyvim.plugins.extras.lang.python"   }, -- pyright LSP, black, ruff
  { import = "lazyvim.plugins.extras.lang.json"     }, -- JSON schema support
  { import = "lazyvim.plugins.extras.lang.yaml"     }, -- YAML schema support
  -- { import = "lazyvim.plugins.extras.lang.bash" },   -- disabled: nil-path bug in current LazyVim

  -- Uncomment as you work in these languages:
  -- { import = "lazyvim.plugins.extras.lang.typescript" },
  -- { import = "lazyvim.plugins.extras.lang.rust" },
  -- { import = "lazyvim.plugins.extras.lang.go" },
  -- { import = "lazyvim.plugins.extras.lang.lua" },

  -- UI extras
  { import = "lazyvim.plugins.extras.editor.aerial"  }, -- code outline panel (<leader>cs)
}
