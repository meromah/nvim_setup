-- Lua LSP
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
})
vim.lsp.enable("lua_ls")

-- Python
vim.lsp.config("pyright", {})
vim.lsp.enable("pyright")

-- TypeScript
vim.lsp.config("ts_ls", {})
vim.lsp.enable("ts_ls")

-- java
vim.lsp.enable("jdtls")
