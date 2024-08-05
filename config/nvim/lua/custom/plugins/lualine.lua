return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    options = {
      globalstatus = true,
      disabled_filetypes = {
        statusline = { 'dashboard', 'alpha' },
      },
      section_separators = { left = '', right = '' },
      component_separators = { left = '', right = '' },
    },
    sections = {
      lualine_c = { 'filename' },
      lualine_x = { 'location' },
    },
    extensions = { 'nvim-tree', 'nvim-dap-ui', 'toggleterm', 'quickfix' },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    },
  },
}
