vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-tree").setup({
    git = {
        enable = true,
        ignore = false, -- show all files regardless of gitignore
    },
    actions = {
    	open_file = {
    		window_picker = {
    			enable = false,
    		}
    	}
    }
})

vim.keymap.set('n', '<c-n>', ':NvimTreeFindFileToggle<CR>')
