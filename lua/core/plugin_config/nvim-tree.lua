vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-tree").setup({
    -- While filesystem_watchers.enable is true, libuv fs_event is the *only*
    -- thing that refreshes the tree: nvim-tree gates auto_reload_on_write and
    -- reload_on_bufenter behind `not filesystem_watchers.enable`. And when a
    -- watcher dies (EMFILE) the plugin flips that flag off for the rest of the
    -- session, so with reload_on_bufenter defaulted to false the tree froze and
    -- never recovered -- not even on <c-n>, since toggling reuses the explorer.
    -- Trading watchers for the polling fallbacks adds refresh triggers instead:
    -- reload on :w and on entering the tree buffer.
    filesystem_watchers = {
        enable = false,
    },
    reload_on_bufenter = true,
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
