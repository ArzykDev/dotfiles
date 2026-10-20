-- ~/.config/nvim/init.lua
vim.g.mapleader = ' '
vim.o.number = true
vim.o.signcolumn = 'yes'
vim.o.showmode = false -- lualine shows the mode

vim.pack.add({
  { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' },
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/nvim-lualine/lualine.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/ibhagwan/fzf-lua',
})

-- theme: follows 'background', which Neovim sets from the terminal
require('catppuccin').setup({
  flavour = 'auto',
  background = { light = 'latte', dark = 'macchiato' },
})
vim.cmd.colorscheme('catppuccin')

-- statusline
require('lualine').setup({
  options = {
    globalstatus = true,
    section_separators = { left = '', right = '' },
    component_separators = '',
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { { 'filename', path = 1 } },
    lualine_x = { 'lsp_status', 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
})

-- LSP
vim.lsp.enable({ 'rust_analyzer', 'ts_ls', 'pyright', 'lua_ls' })
vim.diagnostic.config({ virtual_text = true })

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

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
