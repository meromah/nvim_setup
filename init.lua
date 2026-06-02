require("core.plugins")
require("core.keymaps")
require("core.plugin_config.dirload")

local options = {
    termguicolors = true
}

vim.cmd("colorscheme habamax")
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2e3a4a" })
  end,
})
