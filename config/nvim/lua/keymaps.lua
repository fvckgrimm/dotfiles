-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Bufferline
vim.keymap.set('n', '<S-l>', '<cmd>BufferLineCycleNext<CR>', { desc = 'Cycle to next buffer' })
vim.keymap.set('n', '<S-h>', '<cmd>BufferLineCyclePrev<CR>', { desc = 'Cycle to previous buffer' })
vim.keymap.set('n', '<leader>bo', '<cmd>BufferLineCloseOthers<CR>', { desc = 'Delete other buffers' })
vim.keymap.set('n', '<leader>br', '<cmd>BufferLineCloseRight<CR>', { desc = 'Delete buffers to the right' })
vim.keymap.set('n', '<leader>bl', '<cmd>BufferLineCloseLeft<CR>', { desc = 'Delete buffers to the left' })
vim.keymap.set('n', '<leader>bp', '<cmd>BufferLineTogglePin<CR>', { desc = 'Toggle pin' })
vim.keymap.set('n', '<leader>bP', '<Cmd>BufferLineGroupClose ungrouped<CR>', { desc = 'Delete non-pinned buffers' })

-- LazyGit
vim.keymap.set('n', '<leader>gg', '<cmd>LazyGit<CR>', { desc = 'LazyGit (root dir)' })

-- Other keymaps
vim.keymap.set('n', '//', ':noh<CR>')
vim.keymap.set('n', '<C-h>', '<cmd>lua require("luasnip").jump(1)<CR>')
vim.keymap.set('n', '<leader>ff', '<cmd>lua require("telescope.builtin").find_files()<CR>')
vim.keymap.set('n', '<leader>fg', '<cmd>lua require("telescope.builtin").live_grep()<CR>')
vim.keymap.set('n', '<leader>gs', ':Neogit<CR>')
vim.keymap.set('n', '<leader>af', '<cmd>lua vim.lsp.buf.format()<CR>')
vim.keymap.set('n', '<leader>ac', ':Neogen<CR>')
vim.keymap.set('n', '<leader>m', ':MaximizerToggle<CR>')
vim.keymap.set('n', '<leader>t', ':CHADopen<CR>')
vim.keymap.set('n', '<leader>l', '<cmd>lua require("lsp_lines").toggle()<CR>')
vim.keymap.set('n', '<leader>jd', '<cmd>lua vim.lsp.buf.definition()<CR>')
vim.keymap.set('n', '<leader>jr', '<cmd>Lspsaga finder<CR>')
vim.keymap.set('n', '<leader>rs', '<cmd>Lspsaga rename<CR>')
vim.keymap.set('n', '<leader>ca', '<cmd>Lspsaga code_action<CR>')
vim.keymap.set('n', '<F4>', '<cmd>ToggleTerm<CR>')

vim.keymap.set('n', '<leader>lf', '<cmd>lua require("conform").format({ lsp_fallback = true, async = false, timeout_ms = 500 })<CR>', { silent = true })
vim.keymap.set('n', '.', ':')
vim.keymap.set('n', '<leader>bb', '<CMD>Telescope file_browser<CR>')
vim.keymap.set('n', '<leader>w', '<CMD>WhichKey<CR>')
vim.keymap.set('n', '<Tab>', '<CMD>:bnext<CR>')
vim.keymap.set('n', '<leader>c', '<CMD>:bp | bd #<CR>')

vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { noremap = true, silent = true })
-- vim: ts=2 sts=2 sw=2 et
