return {
  'MeanderingProgrammer/markdown.nvim',
  -- You can specify the version if you want
  version = '5.0.0',
  ft = { 'markdown' }, -- Load only for markdown files
  config = function()
    require('markdown').setup {
      -- Add any configuration options here
    }
  end,
  -- If there are any dependencies, you can specify them here
  -- dependencies = {
  --   -- Add any required dependencies
  -- },
}
