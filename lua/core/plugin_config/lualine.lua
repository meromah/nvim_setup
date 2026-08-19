-- Mimics vim's default bottom-right ruler ("line,col") since lualine's
-- built-in `location` component uses a `line:col` separator instead.
local function cursor_location()
  return vim.fn.line(".") .. "," .. vim.fn.virtcol(".")
end

require("lualine").setup({
  options = {
    theme = "tokyonight",
    globalstatus = true,
    section_separators = "",
    component_separators = "",
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },
    lualine_c = { "filename" },
    lualine_x = {
      {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" },
      },
    },
    lualine_y = { "filetype" },
    lualine_z = { cursor_location },
  },
})
