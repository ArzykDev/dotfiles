-- ~/.config/nvim/init.lua
vim.g.mapleader = ' '
vim.o.number = true
vim.o.signcolumn = 'yes'
vim.o.showmode = false -- the statusline shows the mode
vim.o.laststatus = 3 -- one global statusline

vim.pack.add({
  { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' },
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/ibhagwan/fzf-lua',
  'https://github.com/stevearc/conform.nvim',
  'https://github.com/nvim-mini/mini.nvim',
})

-- theme: follows 'background', which Neovim sets from the terminal
require('catppuccin').setup({
  flavour = 'auto',
  background = { light = 'latte', dark = 'macchiato' },
})
vim.cmd.colorscheme('catppuccin')

-- statusline: git and diff sections come from mini.git/mini.diff
require('mini.icons').setup()
require('mini.statusline').setup()

-- LSP
-- biome/eslint only attach when the project has their config, so both can stay enabled
vim.lsp.enable({
  'gopls',
  'rust_analyzer',
  'ts_ls', 'biome', 'eslint',
  'pyright', 'ruff',
  'bashls',
  'lua_ls',
  'jsonls', 'yamlls', 'tombi',
})
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
    },
  },
})
vim.diagnostic.config({ virtual_text = true })

-- formatting: project's biome/prettier/black when present, otherwise the LSP
local web = { 'biome', 'prettier', stop_after_first = true }
require('conform').setup({
  formatters_by_ft = {
    javascript = web, javascriptreact = web, typescript = web, typescriptreact = web,
    json = { 'biome', 'prettier', 'biome_any', stop_after_first = true },
    jsonc = { 'biome', 'prettier', 'biome_any', stop_after_first = true },
    css = web,
    python = { 'black' }, -- only found on PATH inside a venv that installs it
  },
  formatters = {
    biome = { require_cwd = true },
    prettier = { require_cwd = true },
    -- biome outside any project, indenting per the buffer's 'expandtab'/'shiftwidth'
    biome_any = { inherit = 'biome' },
  },
  default_format_opts = { lsp_format = 'fallback' },
  format_on_save = { timeout_ms = 500 },
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

-- git
require('mini.diff').setup()
require('mini.git').setup()
vim.keymap.set('n', '<leader>go', function() MiniDiff.toggle_overlay() end)
vim.keymap.set({ 'n', 'x' }, '<leader>gb', function() MiniGit.show_at_cursor() end)

-- search
vim.keymap.set('n', '<leader>f', '<cmd>FzfLua files<cr>')
vim.keymap.set('n', '<leader>/', '<cmd>FzfLua live_grep<cr>')
vim.keymap.set('n', '<leader>s', '<cmd>FzfLua lsp_document_symbols<cr>')

-- command-line autocompletion
vim.o.wildmode = 'noselect:lastused,full'
vim.o.wildoptions = 'pum,fuzzy'

vim.api.nvim_create_autocmd('CmdlineChanged', {
  pattern = { ':', '/', '?' },
  callback = function() vim.fn.wildtrigger() end,
})

-- keep Up/Down as history navigation instead of menu navigation
vim.keymap.set('c', '<Up>', '<C-U><Up>')
vim.keymap.set('c', '<Down>', '<C-U><Down>')
