require("gitsigns").setup({
  signs = {
    add          = { text = "│" },
    change       = { text = "│" },
    delete       = { text = "_" },
    topdelete    = { text = "‾" },
    changedelete = { text = "~" },
    untracked    = { text = "┆" },
  },
  -- Longer watch/debounce intervals so a slow `git status` (large repo,
  -- network-mounted .git, frequent index touches from a hook) can't make the
  -- signs/status flicker on and off between polls.
  watch_gitdir = {
    interval = 1000,
    follow_files = true,
  },
  update_debounce = 200,
  current_line_blame = false,
  on_attach = function(bufnr)
    local gitsigns = require("gitsigns")

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    map("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next")
      end
    end, "Next git hunk")

    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev")
      end
    end, "Previous git hunk")

    map("n", "<leader>hs", gitsigns.stage_hunk, "Stage hunk")
    map("n", "<leader>hr", gitsigns.reset_hunk, "Reset hunk")
    map("n", "<leader>hp", gitsigns.preview_hunk, "Preview hunk")
    map("n", "<leader>hb", function() gitsigns.blame_line({ full = true }) end, "Blame line")
    map("n", "<leader>tb", gitsigns.toggle_current_line_blame, "Toggle current line blame")
  end,
})
