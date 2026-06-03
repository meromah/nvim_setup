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

-- vim.diagnostic.config({
--   virtual_text = true,
-- })

-- vim.keymap.set("n", "<C-k>", function()
--   vim.diagnostic.open_float(nil, {
--     focusable = false,
--     -- border = "rounded",
--     scope = "cursor",
--   })
-- end, { desc = "Show diagnostics under cursor" })

-- pop diagnostic info but running :lua print(vim.inspect(vim.diagnostic.config()))

vim.o.updatetime = 300

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, {
      focusable = false,
      scope = "cursor",
    })
  end,
})
