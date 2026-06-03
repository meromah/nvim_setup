-- bootstrap lazy.nvim if it's not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- enable filetype detection and indentation
vim.cmd [[filetype plugin indent on]]

-- set up plugins
require("lazy").setup({
  { "nvim-tree/nvim-tree.lua" },
  -- {
  --   -- syntax highlighting 
  --   "nvim-treesitter/nvim-treesitter",
  --   build = ":TSUpdate",
  --   config = function()
  --     require("nvim-treesitter.configs").setup({
  --       ensure_installed = {'c', 'lua', 'vim', 'php', 'java'},
  --       sync_install = false,
  --       auto_install = true,
  --       highlight = {
  --         enable = true,
  --       },
  --       indent = {
  --         enable = true,
  --       },
  --     })
  --   end,
  -- },

  {
    -- fuzzy finder plugin -> telescope
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require('telescope').setup({
        defaults = {
          layout_strategy = 'horizontal',
          layout_config = {
            height=0.95,
            preview_width = 0.50,
            width = function(_, max_columns)
              return math.floor(max_columns * 1);
            end,
          },
        }
      })
    end,
  },
  -- { "dense-analysis/ale" }, -- for linting
  -- { "neoclide/coc.nvim", branch = "release" }, -- is a LSP client for linting
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },
  {
    "swaits/universal-clipboard.nvim",
    opts = {
      verbose = false, -- optional: set true to log detection details
    },
  },
  {"numToStr/Comment.nvim"},
  {
    'nvim-java/nvim-java',
    config = function()
      require('java').setup()
    end,
  }
})
