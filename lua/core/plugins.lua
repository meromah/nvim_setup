-- bootstrap lazy.nvim if it's not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.cmd [[filetype plugin indent on]]

require("lazy").setup({
  { "nvim-tree/nvim-tree.lua" },

  -- 1. FUZZY FINDER (Telescope)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require('telescope').setup({
        defaults = {
          layout_strategy = 'horizontal',
          layout_config = {
            height = 0.95,
            preview_width = 0.50,
            width = function(_, max_columns)
              return math.floor(max_columns * 1)
            end,
          },
        }
      })
      -- telescope-fzf-native is built (make) as a dependency below but was
      -- never loaded, so telescope was falling back to its default Lua
      -- sorter instead of the compiled fzf matcher.
      require('telescope').load_extension('fzf')
    end,
  },

  -- 2. MODERN LSP ECOSYSTEM (Neovim 0.11+ Native Sync)
  {
    "williamboman/mason.nvim",
    config = true
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "intelephense", "vue_ls", "ts_ls" }, 
    }
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local cmp_capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Setup keymaps globally when ANY lsp client attaches to a buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf, remap = false }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_next, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
        end,
      })

      -- Modern PHP Config
      vim.lsp.config("intelephense", {
        capabilities = cmp_capabilities,
      })

      -- Modern Vue Config (Volar)
      -- NOTE: Mason's vue-language-server package bundles typescript@7.x, which lacks the
      -- classic `ts.server` API @vue/language-server relies on. Force it to use the
      -- project's own typescript install instead via --tsdk.
      local project_tsdk = vim.fn.getcwd() .. "/node_modules/typescript/lib"
      vim.lsp.config("vue_ls", {
        cmd = vim.loop.fs_stat(project_tsdk)
          and { "vue-language-server", "--stdio", "--tsdk=" .. project_tsdk }
          or { "vue-language-server", "--stdio" },
        capabilities = cmp_capabilities,
        init_options = {
          vue = { hybridMode = true },
        },
      })

      -- Safely locate Vue Language Server for TypeScript (Mason 2.0+ pattern)
      local vue_language_server_path = vim.fn.expand("$MASON/packages/vue-language-server/node_modules/@vue/language-server")
      
      -- Fallback to default local paths if env variables aren't initialized yet
      if vue_language_server_path == "" or not vim.loop.fs_stat(vue_language_server_path) then
        vue_language_server_path = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
      end

      -- Modern TypeScript Config
      vim.lsp.config("ts_ls", {
        capabilities = cmp_capabilities,
        init_options = {
          plugins = {
            {
              name = "@vue/typescript-plugin",
              location = vue_language_server_path,
              languages = { "vue" },
            },
          },
        },
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
      })

      -- Fire them up!
      vim.lsp.enable({ "intelephense", "vue_ls", "ts_ls" })
    end
  },
  -- 3. UTILITIES & COMPLETION
  {
    "swaits/universal-clipboard.nvim",
    opts = { verbose = false },
  },
  {
    -- compeletion plugin
    "hrsh7th/nvim-cmp",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
    },
    config = function()
        local cmp = require("cmp")
        cmp.setup({
          mapping = cmp.mapping.preset.insert({
              ["<Tab>"] = cmp.mapping.confirm({ select = true }),
              ["<C-Space>"] = cmp.mapping.complete(),
          }),
          sources = {
              { name = "nvim_lsp" },
              { name = "buffer" },
              { name = "path" },
          },
        })
    end,
  },
  {
    -- theme plugin
    "folke/tokyonight.nvim",
    lazy = false,    -- Load immediately
    priority = 1000, -- Load before others
    config = function()
      vim.cmd([[colorscheme tokyonight]])
    end,
  },
  {
    -- file fzf finder plugin
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- optional but recommended
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    }
  },
  {
    -- Parser installer for the treesitter engine that ships inside Neovim.
    -- Nvim bundles only c/lua/markdown/query/vim/vimdoc parsers, so php has no
    -- syntax tree out of the box and treesitter-context has nothing to render.
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    -- The `main` rewrite explicitly does not support lazy-loading.
    lazy = false,
    build = ":TSUpdate",
    config = function()
      -- Deliberately php-only. `main` installs into stdpath("data")/site, which
      -- is *prepended* to runtimepath, so installing a language Neovim already
      -- bundles would shadow the built-in parser. Keep the blast radius here.
      require("nvim-treesitter").install({ "php" })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
        require("treesitter-context").setup({
        enable = true,       -- Enable this plugin
        max_lines = 3,       -- How many lines the window should span
        trim_scope = 'outer', -- Which context lines to discard if max_lines is exceeded
        })
    end
  },
  {
    "lewis6991/gitsigns.nvim"
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  {
    -- toggle current window to fullscreen and back
    "szw/vim-maximizer",
  }
})

-- NOTE: treesitter highlighting is intentionally NOT enabled (no
-- vim.treesitter.start()). php files keep their regex highlighting from
-- runtime/syntax/php.vim, and treesitter-context falls back to it for the
-- sticky window (see its render.lua highlight_contexts). Only the parser is
-- installed, purely so a syntax tree exists for the context lookup.
