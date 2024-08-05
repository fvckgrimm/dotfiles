return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'mason.nvim',
      'williamboman/mason-lspconfig.nvim',
    },
    opts = {
      servers = {
        --tsserver = {},
        --nil_ls = {},
        pylsp = {
          settings = {
            pylsp = {
              plugins = {
                autopep8 = { enabled = false },
                black = { enabled = false },
                flake8 = { enabled = false },
                mccabe = { enabled = false },
                memestra = { enabled = false },
                pycodestyle = { enabled = false },
                pydocstyle = { enabled = false },
                isort = { enabled = false },
                pyflakes = { enabled = false },
                pylint = { enabled = false },
                pylsp_mypy = { enabled = false },
                yapf = { enabled = false },
              },
            },
          },
        },
        ruff_lsp = {},
        --nixd = {},
        lua_ls = {},
        bashls = {},
        gopls = {
          cmd = { 'gopls' },
          filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
        },
        --nimls = {
        --  cmd = { 'nimlangserver' },
        --  filetypes = { 'nim' },
        --},
        phpactor = {
          cmd = { 'phpactor', 'language-server' },
          filetypes = { 'php' },
        },
        --tailwindcss = {
        --  cmd = { 'tailwindcss-language-server' },
        --  filetypes = { 'html', 'css', 'tsx', 'tmpl', 'php', 'svelte' },
        --},
      },
    },
    config = function(_, opts)
      local lspconfig = require 'lspconfig'
      local mason_lspconfig = require 'mason-lspconfig'

      mason_lspconfig.setup {
        ensure_installed = vim.tbl_keys(opts.servers),
      }

      mason_lspconfig.setup_handlers {
        function(server_name)
          lspconfig[server_name].setup(opts.servers[server_name])
        end,
      }
    end,
  },
  {
    'williamboman/mason.nvim',
    cmd = 'Mason',
    keys = { { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason' } },
    opts = {
      ensure_installed = {
        'stylua',
        'shfmt',
      },
    },
    config = function(_, opts)
      require('mason').setup(opts)
      local mr = require 'mason-registry'
      for _, tool in ipairs(opts.ensure_installed) do
        local p = mr.get_package(tool)
        if not p:is_installed() then
          p:install()
        end
      end
    end,
  },
}
