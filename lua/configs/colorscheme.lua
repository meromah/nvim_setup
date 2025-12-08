  local colorscheme = "tokyonight"
  local ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
  vim.o.background = "dark" -- or "light" for light mode
  if not ok then
    vim.notify("colorscheme " .. colorscheme .. " not found!")
    return
  end
-- Override comment color
vim.api.nvim_set_hl(0, "Comment", { fg = "#a7b0d6", italic = true })
