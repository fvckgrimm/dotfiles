return {
  'akinsho/bufferline.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  version = '*',
  opts = {
    options = {
      mode = 'buffers',
      diagnostics = 'nvim_lsp',
      indicator = {
        icon = ' ', -- You can change this to any character you prefer
        style = 'none',
      },
      -- separator_style = "slant", -- Uncomment if you want slant style
      close_icon = '󰅚',
      buffer_close_icon = '󰅙',
      modified_icon = '󰀨',
      offsets = {
        {
          filetype = 'neo-tree',
          text = 'File Explorer',
          text_align = 'center',
          separator = false,
        },
      },
      diagnostics_indicator = function(count, level)
        local icon = level:match 'error' and ' ' or ''
        return ' ' .. icon .. count
      end,
    },
    highlights = {
      indicator_selected = {
        fg = '#89b4fa',
      },
      -- Uncomment and adjust other highlight groups as needed
      -- fill = {
      --   fg = "#5a5b64",
      --   bg = "#ffffff",
      -- },
      -- background = {
      --   fg = "#5a5b64",
      --   bg = "#000000",
      -- },
      -- You can add more highlight groups here
    },
  },
  config = function(_, opts)
    require('bufferline').setup(opts)
  end,
}
