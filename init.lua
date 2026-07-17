require("core.plugins")
require("core.keymaps")
require("core.plugin_config.dirload")

vim.opt.termguicolors = true

local function apply_custom_highlights()
  vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2e3a4a" })

  -- Brighter variants of tokyonight's severity colors (its base error/info are
  -- muted), so text right under the underline stays legible against the dark
  -- background instead of blending in.
  local ok, tokyonight_colors = pcall(function()
    return require("tokyonight.colors").setup()
  end)
  local bright_fg = {
    Error = ok and tokyonight_colors.red or "#ff757f",
    Warn = ok and tokyonight_colors.yellow or "#ffc777",
    Info = ok and tokyonight_colors.cyan or "#86e1fc",
    Hint = ok and tokyonight_colors.teal or "#4fd6be",
  }

  -- undercurl (curly underline) relies on extended terminal escape codes that
  -- aren't reliably supported through every terminal/multiplexer chain; plain
  -- underline renders consistently everywhere.
  for _, name in ipairs({ "Error", "Warn", "Info", "Hint" }) do
    local hl_name = "DiagnosticUnderline" .. name
    local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = false })
    hl.undercurl = false
    hl.underline = true
    hl.fg = bright_fg[name]
    if hl.cterm then
      hl.cterm.undercurl = false
      hl.cterm.underline = true
    end
    vim.api.nvim_set_hl(0, hl_name, hl)
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = apply_custom_highlights,
})

-- core.plugins applies the colorscheme synchronously on startup, which fires
-- the ColorScheme event above before this autocmd is even registered. Apply
-- once here so the overrides take effect on the very first load too.
apply_custom_highlights()

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
