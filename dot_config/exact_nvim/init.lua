-- ~/.config/nvim/init.lua
vim.g.mapleader = ' '
vim.o.number = true
vim.o.signcolumn = 'yes'
vim.o.showmode = false -- the statusline shows the mode
vim.o.laststatus = 3 -- one global statusline
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.scrolloff = 8

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
  'basedpyright', 'ruff',
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
vim.keymap.set('n', '<leader>go', function() MiniDiff.toggle_overlay() end, { desc = 'Toggle diff overlay' })
vim.keymap.set({ 'n', 'x' }, '<leader>gb', function() MiniGit.show_at_cursor() end, { desc = 'Git history at cursor' })

-- files: also replaces netrw for `nvim dir` and `:e dir`
require('mini.files').setup()
vim.keymap.set('n', '<leader>e', function()
  local path = vim.api.nvim_buf_get_name(0)
  MiniFiles.open(path ~= '' and path or nil)
end, { desc = 'File explorer' })

-- editing: aN/iN keep the built-in v_an/v_in selection (LSP selectionRange) intact
require('mini.ai').setup({ mappings = { around_next = 'aN', inside_next = 'iN' } })
require('mini.surround').setup()

-- key hints after a pause
local miniclue = require('mini.clue')
miniclue.setup({
  triggers = {
    { mode = { 'n', 'x' }, keys = '<Leader>' },
    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },
    { mode = 'i', keys = '<C-x>' },
    { mode = { 'n', 'x' }, keys = 'g' },
    { mode = { 'n', 'x' }, keys = "'" },
    { mode = { 'n', 'x' }, keys = '`' },
    { mode = { 'n', 'x' }, keys = '"' },
    { mode = { 'i', 'c' }, keys = '<C-r>' },
    { mode = 'n', keys = '<C-w>' },
    { mode = { 'n', 'x' }, keys = 'z' },
  },
  clues = {
    { mode = { 'n', 'x' }, keys = '<Leader>g', desc = '+Git' },
    miniclue.gen_clues.square_brackets(),
    miniclue.gen_clues.builtin_completion(),
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
  },
})

-- search
vim.keymap.set('n', '<leader>f', '<cmd>FzfLua files<cr>', { desc = 'Find files' })
vim.keymap.set('n', '<leader>/', '<cmd>FzfLua live_grep<cr>', { desc = 'Grep' })
vim.keymap.set('n', '<leader>s', '<cmd>FzfLua lsp_document_symbols<cr>', { desc = 'Document symbols' })

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
