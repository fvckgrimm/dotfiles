return {
  {
    'neovim/nvim-lspconfig',
    --event = { 'BufReadPre', 'BufNewFile' },
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
        ruff = {},
        --nixd = {},
        --lua_ls = {},
        --bashls = {},
        gopls = {
          cmd = { 'gopls' },
          filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
        },
        rust_analyzer = {},
        vtsls = {
          cmd = {
            vim.fn.expand('~') .. '/.local/share/mise/installs/npm-vtsls-language-server/latest/node_modules/.bin/vtsls',
            '--stdio',
          },
          filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
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
      local servers = opts.servers

      -- Apply per-server overrides (cmd/filetypes/settings/etc.) and enable
      -- each configured server using the modern native LSP API.
      for server_name, server_opts in pairs(servers) do
        local ok, err = pcall(function()
          if server_opts and not vim.tbl_isempty(server_opts) then
            vim.lsp.config(server_name, server_opts)
          end
          vim.lsp.enable(server_name)
        end)
        if not ok then
          vim.notify('Error enabling ' .. server_name .. ': ' .. err, vim.log.levels.ERROR)
        end
      end

      -- Enable gleam (not in the opts.servers table above).
      local gleam_ok, gleam_err = pcall(function()
        vim.lsp.enable('gleam')
      end)
      if not gleam_ok then
        vim.notify('Error enabling gleam: ' .. gleam_err, vim.log.levels.ERROR)
      end

      local configured = vim.tbl_keys(servers)
      table.insert(configured, 'gleam')

      require('mason-lspconfig').setup {
        ensure_installed = vim.tbl_keys(servers),
        -- Only auto-enable the servers we've explicitly configured above, so
        -- mason never attaches servers we didn't ask for.
        automatic_enable = configured,
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
