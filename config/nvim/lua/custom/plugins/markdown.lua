return {
  'MeanderingProgrammer/markdown.nvim',
  main = 'render-markdown',
  opts = {},
  name = 'render-markdown',
  ft = { 'markdown' }, -- Load only for markdown files
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'echasnovski/mini.nvim', -- Assuming you use the mini.nvim suite
  },
  config = function()
    require('render-markdown').setup {
      -- Add any configuration options here
    }
  end,
}
