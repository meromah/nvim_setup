vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.showcmd = true
vim.opt.autowrite = true
vim.opt.cursorline = true
vim.opt.autoread = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.number = true

vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.relativenumber = true


vim.api.nvim_set_keymap('i', 'jk', '<Esc>', { noremap = true, silent = true })
