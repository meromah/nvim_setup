local builtin = require('telescope.builtin')

vim.keymap.set('n', '<c-p>', builtin.find_files, {})
vim.keymap.set('n', '<Space><Space>', builtin.oldfiles, {})
vim.keymap.set('n', '<Space>fg', builtin.live_grep, {})
vim.keymap.set('n', '<Space>fG', function()
  local start_dir = vim.fn.expand('%:p:h')
  if start_dir == '' or vim.fn.isdirectory(start_dir) == 0 then
    start_dir = vim.fn.getcwd()
  end
  local dir = vim.fn.input('Grep in directory: ', start_dir .. '/', 'dir')
  if dir == '' then
    return
  end
  dir = vim.fn.expand(dir)
  if vim.fn.isdirectory(dir) == 0 then
    vim.notify('Not a directory: ' .. dir, vim.log.levels.ERROR)
    return
  end
  builtin.live_grep({ search_dirs = { dir } })
end, {})
vim.keymap.set('n', '<Space>fh', builtin.help_tags, {})


vim.api.nvim_create_autocmd("User", {
  pattern = "TelescopePreviewerLoaded",
  callback = function(args)
    if args.data.filetype ~= "help" then
      vim.wo.number = true
      vim.wo.relativenumber = true
    end
  end,
})
