return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'williamboman/mason.nvim', config = true },
    'williamboman/mason-lspconfig.nvim',
    {
      'folke/lazydev.nvim',
      ft = 'lua',
      opts = {
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      },
    },
  },
  config = function()
    local on_attach = function(client, bufnr)
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })

      vim.keymap.set('n', '<leader>ih', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
      end, { buffer = bufnr, desc = 'Toggle inlay hints' })

      client.server_capabilities.semanticTokensProvider = nil

      local nmap = function(keys, func, desc)
        if desc then desc = 'LSP: ' .. desc end
        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
      end

      nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
      nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
      nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
      nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
      nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
      nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
      nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
      nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
      nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
      nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
      nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
      nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
      nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
      nmap('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, '[W]orkspace [L]ist Folders')

      vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
        vim.lsp.buf.format()
      end, { desc = 'Format current buffer with LSP' })
    end

    require('mason').setup()
    require('mason-lspconfig').setup()

    local servers = {
      intelephense = {
        filetypes = { 'php' },
        init_options = {
          licenceKey = "00EQQ3RLLHSB4FE",
          globalStoragePath = vim.fn.expand("~/Library/Application Support/intelephense"),
        },
        settings = {
          intelephense = {
            stubs = {
              "apache", "bcmath", "bz2", "calendar", "com_dotnet", "Core", "ctype", "curl",
              "date", "dba", "dom", "enchant", "exif", "FFI", "fileinfo", "filter", "fpm",
              "ftp", "gd", "gettext", "gmp", "hash", "iconv", "imap", "intl", "json",
              "ldap", "libxml", "mbstring", "meta", "mysqli", "oci8", "odbc", "openssl",
              "pcntl", "pcre", "PDO", "pdo_ibm", "pdo_mysql", "pdo_pgsql", "pdo_sqlite",
              "pgsql", "Phar", "posix", "pspell", "readline", "Reflection", "session",
              "shmop", "SimpleXML", "snmp", "soap", "sockets", "sodium", "SPL", "sqlite3",
              "standard", "superglobals", "sysvmsg", "sysvsem", "sysvshm", "tidy", "tokenizer",
              "xml", "xmlreader", "xmlrpc", "xmlwriter", "xsl", "Zend OPcache", "zip", "zlib",
              "wordpress", "phpunit",
            },
            files = { maxSize = 5000000 },
            environment = { includePaths = {} },
            licenceKey = "00EQQ3RLLHSB4FE",
            inlayHints = {
              parameterNames = { enabled = "all" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              functionReturnTypes = { enabled = true },
            },
          },
        },
      },
      lua_ls = {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            hint = { arrayIndex = "Disable" },
          },
        },
      },
    }

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

    local mason_lspconfig = require 'mason-lspconfig'
    mason_lspconfig.setup {
      ensure_installed = vim.tbl_keys(servers),
      handlers = {
        function(server_name)
          if server_name == "intelephense" then return end
          local server_config = servers[server_name] or {}
          require('lspconfig')[server_name].setup {
            capabilities = capabilities,
            on_attach = on_attach,
            settings = server_config.settings or server_config,
            filetypes = server_config.filetypes,
            init_options = server_config.init_options,
          }
        end,
      },
    }

    -- Configure intelephense separately (nvim 0.11+ API)
    local intelephense_licence_path = vim.fn.expand("~/Library/Application Support/intelephense/licence.txt")
    local intelephense_licence_key = nil
    if vim.fn.filereadable(intelephense_licence_path) == 1 then
      intelephense_licence_key = vim.fn.readfile(intelephense_licence_path)[1]
    end

    vim.lsp.config.intelephense = {
      cmd = { 'intelephense', '--stdio' },
      filetypes = { 'php' },
      root_markers = { 'composer.json', '.git' },
      init_options = {
        licenceKey = intelephense_licence_key,
        globalStoragePath = vim.fn.expand("~/Library/Application Support/intelephense"),
      },
      settings = servers.intelephense.settings,
    }
    vim.lsp.enable('intelephense')

    -- Configure Vue + TypeScript (nvim 0.11+ API)
    local vue_language_server_path = vim.fn.expand(
      '~/.local/share/nvim/mason/packages/vue-language-server/node_modules/@vue/language-server')

    vim.lsp.config.ts_ls = {
      init_options = {
        plugins = {
          { name = '@vue/typescript-plugin', location = vue_language_server_path, languages = { 'vue' } },
        },
        preferences = {
          -- Enable auto-imports
          includeCompletionsForModuleExports = true,
          includeCompletionsWithInsertText = true,
          -- Auto-import suggestions
          includeCompletionsForImportStatements = true,
          includeAutomaticOptionalChainCompletions = true,
        },
      },
      filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'vue' },
    }
    vim.lsp.enable('ts_ls')

    vim.lsp.config.vue_ls = {
      cmd = { 'vue-language-server', '--stdio' },
      filetypes = { 'vue' },
      root_markers = { 'package.json', '.git' },
    }
    vim.lsp.enable('vue_ls')
  end,
}
