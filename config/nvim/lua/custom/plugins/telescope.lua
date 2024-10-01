return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-ui-select.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    'nvim-telescope/telescope-file-browser.nvim',
  },
  cmd = 'Telescope',
  keys = {
    { '<leader><space>', '<cmd>Telescope find_files<cr>', desc = 'Find project files' },
    { '<leader>/', '<cmd>Telescope live_grep<cr>', desc = 'Grep (root dir)' },
    { '<leader>:', '<cmd>Telescope command_history<cr>', desc = 'Command History' },
    { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find project files' },
    { '<leader>fr', '<cmd>Telescope oldfiles<cr>', desc = 'Find text' },
    { '<leader>fR', '<cmd>Telescope resume<cr>', desc = 'Resume' },
    { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Recent' },
    { '<leader>fb', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
    { '<C-p>', '<cmd>Telescope git_files<cr>', desc = 'Search git files' },
    { '<leader>gc', '<cmd>Telescope git_commits<cr>', desc = 'Commits' },
    { '<leader>gs', '<cmd>Telescope git_status<cr>', desc = 'Status' },
    { '<leader>sa', '<cmd>Telescope autocommands<cr>', desc = 'Auto Commands' },
    { '<leader>sb', '<cmd>Telescope current_buffer_fuzzy_find<cr>', desc = 'Buffer' },
    { '<leader>sc', '<cmd>Telescope command_history<cr>', desc = 'Command History' },
    { '<leader>sC', '<cmd>Telescope commands<cr>', desc = 'Commands' },
    { '<leader>sD', '<cmd>Telescope diagnostics<cr>', desc = 'Workspace diagnostics' },
    { '<leader>sh', '<cmd>Telescope help_tags<cr>', desc = 'Help pages' },
    { '<leader>sH', '<cmd>Telescope highlights<cr>', desc = 'Search Highlight Groups' },
    { '<leader>sk', '<cmd>Telescope keymaps<cr>', desc = 'Keymaps' },
    { '<leader>sM', '<cmd>Telescope man_pages<cr>', desc = 'Man pages' },
    { '<leader>sm', '<cmd>Telescope marks<cr>', desc = 'Jump to Mark' },
    { '<leader>so', '<cmd>Telescope vim_options<cr>', desc = 'Options' },
    { '<leader>sR', '<cmd>Telescope resume<cr>', desc = 'Resume' },
    { '<leader>cs', '<cmd>Telescope colorscheme<cr>', desc = 'Colorscheme preview' },

    { '<leader>lR', '<cmd>Telescope lsp_references<cr>', desc = 'Find all references' },
    { '<leader>lI', '<cmd>Telescope lsp_implementations<cr>', desc = 'Find implementations' },
    { '<leader>lS', '<cmd>Telescope lsp_document_symbols<cr>', desc = 'Document symbols' },
    { '<leader>lW', '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>', desc = 'Workspace symbols' },
    { '<leader>lD', '<cmd>Telescope lsp_definitions<cr>', desc = 'Go to definition' },
    { '<leader>lt', '<cmd>Telescope lsp_type_definitions<cr>', desc = 'Go to type definition' },
  },
  opts = {
    defaults = {
      border = {},
      layout_strategy = 'horizontal',
      sorting_strategy = 'ascending',
      prompt_prefix = '   ',
      selection_caret = '  ',
      entry_prefix = '  ',
      color_devicons = true,
      set_env = { COLORTERM = 'truecolor' },
      layout_config = {
        horizontal = {
          prompt_position = 'top',
        },
      },
      file_ignore_patterns = {
        '^node_modules/',
        '^.devenv/',
        '^.direnv/',
        '^.git/',
      },
      borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
      vimgrep_arguments = {
        'rg',
        '-L',
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
        '--fixed-strings',
      },
      mappings = {
        i = {
          ['<esc>'] = 'close',
          ['<S-j>'] = 'move_selection_next',
          ['<S-k>'] = 'move_selection_previous',
          ['<C-j>'] = 'move_selection_next',
          ['<C-k>'] = 'move_selection_previous',
        },
      },
    },
    pickers = {
      find_files = {
        hidden = true,
      },
    },
    extensions = {
      ['ui-select'] = {
        require('telescope.themes').get_dropdown {},
      },
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = 'smart_case',
      },
      file_browser = {
        hidden = true,
        depth = 9999999999,
        auto_depth = true,
      },
    },
  },
  config = function(_, opts)
    local telescope = require 'telescope'
    telescope.setup(opts)
    telescope.load_extension 'ui-select'
    telescope.load_extension 'fzf'
    telescope.load_extension 'file_browser'
  end,
}
