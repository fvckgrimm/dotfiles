return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  opts = {
    notify = {
      enabled = false,
    },
    messages = {
      enabled = true,
    },
    lsp = {
      message = {
        enabled = true,
      },
      progress = {
        enabled = false,
        view = 'mini',
      },
    },
    popupmenu = {
      enabled = true,
      backend = 'nui',
    },
    format = {
      filter = {
        pattern = { ':%s*%%s*s:%s*', ':%s*%%s*s!%s*', ':%s*%%s*s/%s*', '%s*s:%s*', ':%s*s!%s*', ':%s*s/%s*' },
        icon = '',
        lang = 'regex',
      },
      replace = {
        pattern = { ':%s*%%s*s:%w*:%s*', ':%s*%%s*s!%w*!%s*', ':%s*%%s*s/%w*/%s*', '%s*s:%w*:%s*', ':%s*s!%w*!%s*', ':%s*s/%w*/%s*' },
        icon = '󱞪',
        lang = 'regex',
      },
    },
  },
  dependencies = {
    'MunifTanjim/nui.nvim',
    'rcarriga/nvim-notify',
  },
}
