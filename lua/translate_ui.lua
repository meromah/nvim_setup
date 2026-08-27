-- Popup UI for translate.nvim.
--
-- The backend is slow and highly variable (measured 6.7s-33.3s per request,
-- essentially all of it time-to-first-byte in the Google Apps Script proxy the
-- plugin's `google` command talks to). The plugin's own `floating` output only
-- creates its window once the response lands, so for those seconds there is no
-- feedback at all and the command looks like it silently failed.
--
-- So this module splits the window's life in two: open a spinner immediately,
-- then fill that same window in place when the text arrives.
--
-- The popup never steals focus. Dismiss-on-CursorMoved is ARMED ONLY ONCE THE
-- TEXT HAS LANDED, which is the whole trick: during the multi-second wait there
-- is no autocmd at all, so a stray keypress can't throw the pending result away
-- (the bug in the first version), and afterwards the window still gets out of
-- your way on the next cursor move without needing an explicit :q.
--
-- That autocmd is scoped to the SOURCE buffer, so clicking into the popup to
-- yank from it doesn't count as a cursor move and won't close it. q / <Esc> /
-- :q close it too, once it is focused.

local api = vim.api

local M = {}

local FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local TIMEOUT_MS = 120000
local BORDER = 2 -- rounded border costs a row/col on each side

---@type table|nil
local state = nil

local function stop_timer()
  if state and state.timer then
    vim.fn.timer_stop(state.timer)
    state.timer = nil
  end
end

local function close()
  if not state then
    return
  end
  local st = state
  state = nil -- nil first: nvim_win_close re-enters this via WinClosed
  if st.timer then
    vim.fn.timer_stop(st.timer)
  end
  pcall(api.nvim_win_close, st.win, true)
  pcall(api.nvim_buf_delete, st.buf, { force = true })
end

M.close = close

-- The scratch buffer is kept nomodifiable so it can't be typed into by accident;
-- unlock only for the moment it takes to write.
local function set_lines(buf, lines)
  if not api.nvim_buf_is_valid(buf) then
    return
  end
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  vim.bo[buf].modifiable = false
end

local function geometry(lines)
  local w = 1
  for _, l in ipairs(lines) do
    w = math.max(w, vim.fn.strdisplaywidth(l))
  end
  w = math.max(24, math.min(w, math.floor(vim.o.columns * 0.8) - BORDER))
  local h = math.max(1, math.min(#lines, math.floor(vim.o.lines * 0.4)))
  return w, h
end

-- Anchored to the editor, not to "cursor": the cursor ends up inside the popup,
-- so a cursor-relative window would re-anchor to itself when it is resized to
-- fit the translation.
local function place(anchor, w, h)
  local row = anchor.row
  if row + h + BORDER > vim.o.lines - 1 then
    row = math.max(0, anchor.row - 1 - h - BORDER)
  end
  local col = math.max(0, math.min(anchor.col, vim.o.columns - w - BORDER))
  return row, col
end

-- Arm "close on the next cursor move in the source buffer". Deliberately NOT
-- called while the request is in flight -- only once there is something to read.
-- Scoped to the source buffer so moving around inside the popup (after clicking
-- into it to copy) cannot trigger it.
local function arm_dismiss()
  if not state then
    return
  end
  api.nvim_create_autocmd("CursorMoved", {
    buffer = state.src_buf,
    callback = function()
      close()
      return true -- one-shot: returning true deletes the autocmd
    end,
  })
end

---Open the spinner and fire the request. Focus stays in your buffer.
---@param target string #target language code, e.g. "EN"
function M.translate(target)
  -- Leave visual mode first so '< and '> are set for the :'<,'> range below.
  api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

  close() -- only ever one popup alive

  local src_buf = api.nvim_get_current_buf()
  local cur = api.nvim_win_get_cursor(0)
  local sp = vim.fn.screenpos(0, cur[1], cur[2] + 1)
  local anchor = { row = sp.row, col = math.max(0, sp.col - 1) }
  if sp.row == 0 then -- position not currently visible
    anchor = { row = vim.fn.winline(), col = 0 }
  end

  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "translate"
  local lines = { ("  %s  Translating…  0.0s"):format(FRAMES[1]) }
  set_lines(buf, lines)

  local w, h = geometry(lines)
  local row, col = place(anchor, w, h)
  local win = api.nvim_open_win(buf, false, {
    relative = "editor",
    row = row,
    col = col,
    width = w,
    height = h,
    style = "minimal",
    border = "rounded",
    focusable = true,
    zindex = 50,
  })

  state = { win = win, buf = buf, anchor = anchor, src_buf = src_buf, start = vim.loop.hrtime() }

  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true })
  api.nvim_create_autocmd("WinClosed", { pattern = tostring(win), once = true, callback = close })

  local frame = 1
  state.timer = vim.fn.timer_start(90, function()
    if not state or not api.nvim_buf_is_valid(state.buf) then
      return
    end
    local ms = (vim.loop.hrtime() - state.start) / 1e6
    -- Watchdog: if curl dies without writing anything the output callback never
    -- fires, and without this the spinner would run forever. Measured round
    -- trips range 3.4s-33s, so this is deliberately far above the worst case.
    if ms > TIMEOUT_MS then
      stop_timer()
      set_lines(state.buf, { "  translation timed out after 120s" })
      arm_dismiss()
      return
    end
    frame = frame % #FRAMES + 1
    set_lines(state.buf, { ("  %s  Translating…  %.1fs"):format(FRAMES[frame], ms / 1000) })
  end, { ["repeat"] = -1 })

  -- Run the request while the SOURCE buffer is still the current one: the
  -- plugin reads the selection out of buffer 0.
  local ok, err = pcall(vim.cmd, "'<,'>Translate " .. target)
  if not ok then
    stop_timer()
    set_lines(buf, { "  " .. tostring(err):gsub("\n", " ") })
    arm_dismiss()
    return
  end

  -- Focus is deliberately left in the source buffer.
end

---Fill the already-open popup with the finished translation.
---Registered as translate.nvim's `output` handler.
---@param lines string[]|string
function M.fill(lines)
  if type(lines) == "string" then
    lines = { lines }
  end
  if #lines == 0 then
    lines = { "(no translation returned)" }
  end
  -- Popup already dismissed: drop the result rather than resurrecting a window
  -- the user deliberately closed.
  if not state or not api.nvim_win_is_valid(state.win) then
    return
  end

  stop_timer()
  set_lines(state.buf, lines)

  local w, h = geometry(lines)
  local row, col = place(state.anchor, w, h)
  pcall(api.nvim_win_set_config, state.win, {
    relative = "editor",
    row = row,
    col = col,
    width = w,
    height = h,
  })
  pcall(api.nvim_win_set_cursor, state.win, { 1, 0 })

  -- Only now is it safe to let a cursor move dismiss the popup.
  arm_dismiss()
end

return M
