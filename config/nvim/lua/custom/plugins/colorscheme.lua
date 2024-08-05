return {
  {
    'ellisonleao/gruvbox.nvim',
    lazy = true,
    opts = {
      transparent_mode = false,
    },
  },
  {
    'folke/tokyonight.nvim',
    lazy = true,
    opts = {
      style = 'night',
      transparent = false,
      on_highlights = function(hl, c)
        local prompt = '#2d3149'
        hl.TelescopeNormal = {
          bg = c.bg_dark,
          fg = c.fg_dark,
        }
        hl.TelescopeBorder = {
          bg = c.bg_dark,
          fg = c.bg_dark,
        }
        hl.TelescopePromptNormal = {
          bg = prompt,
        }
        hl.TelescopePromptBorder = {
          bg = prompt,
          fg = prompt,
        }
        hl.TelescopePromptTitle = {
          bg = prompt,
          fg = prompt,
        }
        hl.TelescopePreviewTitle = {
          bg = c.bg_dark,
          fg = c.bg_dark,
        }
        hl.TelescopeResultsTitle = {
          bg = c.bg_dark,
          fg = c.bg_dark,
        }
      end,
    },
  },
  {
    'nyoom-engineering/oxocarbon.nvim',
    lazy = true,
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    opts = {
      background = {
        light = 'macchiato',
        dark = 'mocha',
      },
      flavour = 'frappe',
      no_bold = false,
      no_italic = false,
      no_underline = false,
      transparent_background = false,
      integrations = {
        cmp = true,
        noice = true,
        notify = true,
        gitsigns = true,
        which_key = true,
        illuminate = {
          enabled = true,
        },
        treesitter = true,
        treesitter_context = true,
        telescope = { enabled = true },
        indent_blankline = { enabled = true },
        mini = { enabled = true },
        native_lsp = {
          enabled = true,
          inlay_hints = {
            background = true,
          },
          underlines = {
            errors = { 'underline' },
            hints = { 'underline' },
            information = { 'underline' },
            warnings = { 'underline' },
          },
        },
      },
    },
    config = function(_, opts)
      require('catppuccin').setup(opts)
      vim.cmd.colorscheme 'catppuccin'
    end,
  },
}
