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



vim.api.nvim_set_keymap('i', 'jk', '<Esc>', { noremap = true, silent = true })


vim.api.nvim_create_autocmd('TermOpen', {
    group = vim.api.nvim_create_augroup('custom-term-open', { clear = true}),
    callback = function()
        vim.opt.number = false
        vim.opt.relativenumber = false
    end,
})


-- normal mode - toggle (new, close) terminal as a bottom window
vim.keymap.set('n', '<Space>t', function()

    local window = vim.api.nvim_get_current_win()

    if vim.bo.buftype == 'terminal' then
        vim.api.nvim_win_close(window, true)
        return
    end

    -- otherwise
    vim.cmd('vnew')
    vim.cmd('term')
    vim.cmd('wincmd J')

    vim.api.nvim_win_set_height(window, 12)
    vim.cmd('startinsert')
end, { noremap = true, silent = true })


vim.keymap.set('t', 'jk', [[<C-\><C-n>]], { noremap = true, silent = true })
