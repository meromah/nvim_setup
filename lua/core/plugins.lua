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
  -- file explorer sidebar; toggle with <c-n> (keymap in plugin_config/nvim-tree.lua)
  { "nvim-tree/nvim-tree.lua" },

  -- 1. FUZZY FINDER (Telescope)
  -- Keymaps live in plugin_config/telescope.lua: <c-p> find files, <Space>fP
  -- find files scoped to a directory, <Space>fg live grep, <Space>fG live
  -- grep scoped to a directory, <Space><Space> recent files, <Space>fh help tags.
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
  -- No keymap: open the installer UI with the :Mason command.
  {
    "williamboman/mason.nvim",
    config = true
  },
  {
    -- No direct usage: just installs/registers the servers listed below so
    -- nvim-lspconfig can hand them to the native LSP client.
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
  -- No keymap: syncs the system clipboard automatically, nothing to trigger.
  {
    "swaits/universal-clipboard.nvim",
    opts = { verbose = false },
  },
  {
    -- Completion popup; opens automatically while typing in insert mode.
    -- <Tab> confirms the selected entry, <C-Space> forces it open on demand.
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
    -- Colorscheme; applied automatically at startup below, no keymap needed.
    -- Switch it manually any time with :colorscheme tokyonight.
    "folke/tokyonight.nvim",
    lazy = false,    -- Load immediately
    priority = 1000, -- Load before others
    config = function()
      vim.cmd([[colorscheme tokyonight]])
    end,
  },
  {
    -- Second spec for the same plugin as above; lazy.nvim merges specs by
    -- name, so this just adds telescope-fzf-native as a dependency. No
    -- separate keymap: it's the sorter backend activated by the
    -- load_extension('fzf') call in the first telescope spec's config(),
    -- and then used automatically by every telescope picker.
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
    -- No keymap or command of its own: it only feeds treesitter-context below.
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
    -- Sticky scroll: shows the enclosing function/class at the top of the
    -- window automatically while scrolling. No keymap to toggle it.
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
    -- Git hunk signs/blame in the sign column. Keymaps (]c/[c navigate hunks,
    -- <leader>hs/hr/hp stage/reset/preview, <leader>hb/tb blame) are set up
    -- in plugin_config/gitsigns.lua's on_attach.
    "lewis6991/gitsigns.nvim"
  },
  {
    -- Statusline; shown automatically, no keymap needed.
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  {
    -- toggle current window to fullscreen and back, <leader>z (keymap in keymaps.lua)
    "szw/vim-maximizer",
  },
  {
    -- undo history browser (sidebar tree, richer than plain ctrl-z/ctrl-r)
    -- toggle with <leader>u (keymap in keymaps.lua)
    "mbbill/undotree",
  },
  {
    -- Translate a foreign-language selection to English. Select in visual mode
    -- and hit <Space>t. Spelled as a literal <Space> rather than <leader> to
    -- match keymaps.lua, and so the binding can't drift if mapleader changes.
    -- Declared under `keys`, so lazy.nvim only loads the plugin on first use
    -- (measured: 21.6ms, one time -- negligible next to the request itself).
    --
    -- WHY THE CUSTOM UI: the backend is slow and wildly variable -- measured
    -- 6.7s to 33.3s per request, effectively all of it time-to-first-byte
    -- inside the Google Apps Script proxy. With the stock `floating` output
    -- nothing at all happens for that long, so the command looks broken, and
    -- its unscoped CursorMoved autocmd meant an idle keypress during the wait
    -- killed the result. So instead:
    --   1. a spinner popup opens IMMEDIATELY, showing elapsed seconds,
    --   2. focus stays in your buffer -- the popup never steals the cursor,
    --   3. the same window is filled in place when the response arrives,
    --   4. dismiss-on-CursorMoved is armed ONLY THEN, so a stray keypress during
    --      the multi-second wait can't discard a pending result, while a
    --      finished popup still clears itself on the next cursor move with no
    --      explicit :q needed. Click into it and it stays, so you can yank.
    -- A 120s watchdog replaces the spinner with an error rather than spinning
    -- forever if curl dies without producing output.
    --
    -- Order matters in the mapping: <Esc> first so '< '> are set, then open the
    -- popup with enter=false, then run :Translate while the SOURCE buffer is
    -- still current -- the plugin reads the selection out of buffer 0.
    --
    -- READ-ONLY BY CONSTRUCTION: it renders into a throwaway scratch buffer
    -- (nvim_create_buf(false, true), buftype=nofile, nomodifiable) with no file
    -- backing, so nothing can be written to disk from it. The plugin's only
    -- buffer-modifying outputs are `-output=insert` and `-output=replace`; the
    -- mapping passes neither, and the default output is pinned to ours so an
    -- upstream default change can't silently start editing files.
    --
    -- parse_after "window" is given an ABSOLUTE width (76) rather than the
    -- default fraction-of-current-window: by the time the response is parsed
    -- the cursor is inside the popup, so a relative width would measure the
    -- popup and wrap the text to a sliver.
    --
    -- NOTE: the google backend POSTs the selected text to a Google Apps Script
    -- endpoint hosted by the plugin author, not to Google directly. Fine for
    -- OSS, think twice before pointing it at client source.
    "uga-rosa/translate.nvim",
    cmd = "Translate",
    keys = {
      {
        "<Space>t",
        function()
          require("translate_ui").translate("EN")
        end,
        mode = "x",
        silent = true,
        desc = "Translate visual selection",
      },
    },
    config = function()
      require("translate").setup({
        default = {
          command = "google",
          parse_after = "window",
          output = "popup",
        },
        preset = {
          parse_after = { window = { width = 76 } },
        },
        output = {
          popup = { cmd = function(lines) require("translate_ui").fill(lines) end },
        },
      })
    end,
  }
})

-- NOTE: treesitter highlighting is intentionally NOT enabled (no
-- vim.treesitter.start()). php files keep their regex highlighting from
-- runtime/syntax/php.vim, and treesitter-context falls back to it for the
-- sticky window (see its render.lua highlight_contexts). Only the parser is
-- installed, purely so a syntax tree exists for the context lookup.
