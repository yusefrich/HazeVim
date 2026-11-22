-- Glow preview: render the current Markdown file with `glow` in a split on the right.
--
-- glow's ANSI output is fed into a terminal buffer made with nvim_open_term, so the colours
-- show but no process stays alive (and no "[Process exited]" line). Saving the source or
-- resizing the preview renders it again.

local M = {}

local previews = {} -- source buf -> { win, buf }
local group = vim.api.nvim_create_augroup("tools_glow", { clear = true })

local function valid_win(p)
  return p and p.win and vim.api.nvim_win_is_valid(p.win)
end

function M.close(src)
  local p = previews[src]
  previews[src] = nil
  pcall(vim.api.nvim_clear_autocmds, { group = group, buffer = src })
  if valid_win(p) then
    pcall(vim.api.nvim_win_close, p.win, true)
  end
end

function M.render(src)
  local p = previews[src]
  if not valid_win(p) then
    return
  end
  local file = vim.api.nvim_buf_get_name(src)
  p.width = vim.api.nvim_win_get_width(p.win)
  local width = math.max(20, p.width - 2)
  local style = vim.o.background == "light" and "light" or "dark"
  -- Saves and resizes can start renders that end out of order. Only the newest one draws.
  p.gen = (p.gen or 0) + 1
  local gen = p.gen
  vim.system({ "glow", "-s", style, "-w", tostring(width), file }, { text = true }, vim.schedule_wrap(function(res)
    if not valid_win(p) or previews[src] ~= p or p.gen ~= gen then
      return
    end
    if res.code ~= 0 then
      return vim.notify("glow: " .. vim.trim(res.stderr or ""), vim.log.levels.ERROR)
    end
    -- A terminal buffer takes output once, so each render gets a new one in the same window.
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.keymap.set("n", "q", function()
      M.close(src)
    end, { buffer = buf, nowait = true, desc = "Close glow preview" })

    local old, cursor = p.buf, vim.api.nvim_win_get_cursor(p.win)
    p.buf = buf
    -- Show the buffer first: the terminal takes its width from the window it is in when
    -- opened. Opened off-screen, it gets a narrower default and wraps glow's lines.
    vim.api.nvim_win_set_buf(p.win, buf)
    local chan = vim.api.nvim_open_term(buf, {})
    vim.api.nvim_chan_send(chan, (res.stdout:gsub("\r?\n", "\r\n")))
    if old and old ~= buf and vim.api.nvim_buf_is_valid(old) then
      pcall(vim.api.nvim_buf_delete, old, { force = true })
    end
    pcall(vim.api.nvim_buf_set_name, buf, "glow://" .. vim.fn.fnamemodify(file, ":~:."))
    -- The terminal fills in on the next redraw; then restore the line (or go to the top).
    vim.schedule(function()
      if valid_win(p) and p.buf == buf then
        local last = vim.api.nvim_buf_line_count(buf)
        pcall(vim.api.nvim_win_set_cursor, p.win, { old and math.min(cursor[1], last) or 1, 0 })
      end
    end)
  end))
end

function M.open(src)
  local p = { win = nil, buf = nil }
  previews[src] = p
  local from = vim.api.nvim_get_current_win()
  vim.cmd("botright vsplit")
  p.win = vim.api.nvim_get_current_win()
  local wo = vim.wo[p.win]
  wo.number, wo.relativenumber, wo.signcolumn, wo.wrap = false, false, "no", false
  vim.api.nvim_set_current_win(from)

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    buffer = src,
    callback = function()
      M.render(src)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
    group = group,
    buffer = src,
    callback = function()
      M.close(src)
    end,
  })
  M.render(src)
end

--- Open or close the glow preview for the current Markdown buffer.
function M.toggle()
  local src = vim.api.nvim_get_current_buf()
  -- Called from inside a preview: close it.
  for s, p in pairs(previews) do
    if p.buf == src then
      return M.close(s)
    end
  end
  if vim.fn.executable("glow") == 0 then
    return vim.notify("glow: not found on PATH — run `brew install glow`", vim.log.levels.WARN)
  end
  local file = vim.api.nvim_buf_get_name(src)
  if file == "" or vim.bo[src].buftype ~= "" then
    return vim.notify("glow: this buffer has no file", vim.log.levels.WARN)
  end
  if valid_win(previews[src]) then
    return M.close(src)
  end
  if vim.bo[src].modified then
    vim.notify("glow: unsaved changes are not shown until you save", vim.log.levels.INFO)
  end
  M.open(src)
end

-- Full-screen glow: its own start screen (the Markdown file list and search) in a float.

-- One per tab: worktree tabs each get their own glow, and a stale one from another tab
-- (or from before a `:tcd`) is never reused.
local browsers = {} -- tabpage -> { win, buf, job, dir }
local floats = {} -- every glow float: win -> true (start screen) or its render function (file view)

local function git(dir, ...)
  local out = vim.fn.systemlist({ "git", "-C", dir, ... })
  return vim.v.shell_error == 0 and out or nil
end

-- The root of the worktree of the tab cwd, else the tab cwd. Worktree tabs have a tab-local
-- cwd, so each one lists its own files. `git -C` works the same in linked worktrees.
local function root()
  local cwd = vim.fn.getcwd()
  local top = git(cwd, "rev-parse", "--show-toplevel")
  if top and top[1] and top[1] ~= "" then
    return top[1]
  end
  return cwd
end

-- glow applies the .gitignore of the first parent dir that has a `.git` *directory*. A linked
-- worktree has a `.git` file, so for a worktree nested in its main checkout (for example
-- `.claude/worktrees/<name>`) glow uses the main checkout's .gitignore. When that ignores the
-- worktree, glow lists 0 files. Is `dir` such a worktree?
local function hidden_by_parent(dir)
  if vim.fn.isdirectory(dir .. "/.git") == 1 then
    return false
  end
  local parent = vim.fs.dirname(dir)
  local outer = git(parent, "rev-parse", "--show-toplevel")
  if not outer or not outer[1] or outer[1] == "" then
    return false
  end
  vim.fn.system({ "git", "-C", outer[1], "check-ignore", "-q", "--no-index", dir })
  return vim.v.shell_error == 0
end

-- For such a worktree: a mirror dir in the cache with a hard link to each Markdown file that
-- git shows (tracked, or new and not ignored). It is outside every repo, so glow ignores
-- nothing in it. Hard links keep the real modified times, and an edit changes the real file.
local function mirror(dir)
  -- -z: with no -z, git quotes names with non-ASCII bytes ("r\303\251sum\303\251.md").
  local res = vim
    .system({ "git", "-C", dir, "ls-files", "-z", "--cached", "--others", "--exclude-standard", "--", "*.md", "*.markdown" }, { text = true })
    :wait()
  if res.code ~= 0 then
    return dir
  end
  local files = vim.split(res.stdout or "", "\0", { plain = true, trimempty = true })
  local out = vim.fn.stdpath("cache") .. "/glow/" .. vim.fn.sha256(dir):sub(1, 12) .. "/" .. vim.fs.basename(dir)
  vim.fn.delete(out, "rf") -- only links: the real files are not touched
  vim.fn.mkdir(out, "p")
  for _, rel in ipairs(files) do
    local src, dst = dir .. "/" .. rel, out .. "/" .. rel
    if vim.uv.fs_stat(src) then
      vim.fn.mkdir(vim.fs.dirname(dst), "p")
      if not vim.uv.fs_link(src, dst) then
        vim.uv.fs_symlink(src, dst)
      end
    end
  end
  return out
end

local function full_size()
  local h = vim.o.lines - vim.o.cmdheight - (vim.o.laststatus > 0 and 1 or 0)
  return { relative = "editor", row = 0, col = 0, width = vim.o.columns, height = math.max(1, h) }
end

-- Run `cmd` in a terminal in a full-screen float. `q` (in glow, or in Normal mode) ends it,
-- and the float closes when the job exits. Returns win, buf, job.
local function float_job(cmd, cwd, label, on_exit)
  local buf = vim.api.nvim_create_buf(false, true)
  local cfg = full_size()
  cfg.style, cfg.border, cfg.zindex = "minimal", "none", 60
  local win = vim.api.nvim_open_win(buf, true, cfg)
  vim.bo[buf].bufhidden = "wipe"
  -- Opened after the window exists, so glow gets the full width and height.
  local job = vim.fn.jobstart(cmd, {
    term = true,
    cwd = cwd,
    on_exit = vim.schedule_wrap(function()
      if on_exit then
        on_exit(buf)
      end
      floats[win] = nil
      pcall(vim.api.nvim_win_close, win, true)
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end),
  })
  floats[win] = true
  pcall(vim.api.nvim_buf_set_name, buf, "glow://" .. vim.fn.fnamemodify(label, ":~:."))
  -- Keys must reach glow, not Nvim. Re-enter terminal mode whenever the window gets focus
  -- (tab switch, a picker closing, a click), and let `q` quit glow from Normal mode too,
  -- where it would otherwise start a macro recording.
  vim.api.nvim_create_autocmd("BufEnter", { buffer = buf, command = "startinsert" })
  vim.keymap.set("n", "q", function()
    pcall(vim.fn.jobstop, job)
  end, { buffer = buf, nowait = true, desc = "Quit glow" })
  -- glow has mouse support off by default, so the wheel would scroll Nvim's view of the
  -- terminal, not glow's page. Send glow its own scroll keys instead (3 lines a step), in
  -- terminal and Normal mode, so this works with any glow.yml.
  for key, keys in pairs({ ["<ScrollWheelDown>"] = "jjj", ["<ScrollWheelUp>"] = "kkk" }) do
    vim.keymap.set({ "t", "n" }, key, function()
      pcall(vim.fn.chansend, job, keys)
    end, { buffer = buf, desc = "Scroll glow" })
  end
  for _, key in ipairs({ "<ScrollWheelLeft>", "<ScrollWheelRight>" }) do
    vim.keymap.set({ "t", "n" }, key, "<Nop>", { buffer = buf })
  end
  vim.cmd.startinsert()
  return win, buf, job
end

--- Open the glow start screen full screen for the current worktree.
--- Quit glow (`q`, or `<C-c>`) to close it.
function M.browse()
  if vim.fn.executable("glow") == 0 then
    return vim.notify("glow: not found on PATH — run `brew install glow`", vim.log.levels.WARN)
  end
  local tab = vim.api.nvim_get_current_tabpage()
  local dir = root()
  local old = browsers[tab]
  if old and vim.api.nvim_win_is_valid(old.win) then
    if old.dir == dir then
      vim.api.nvim_set_current_win(old.win)
      return vim.cmd.startinsert()
    end
    pcall(vim.fn.jobstop, old.job) -- this tab moved to another worktree: start over
  end
  local show = hidden_by_parent(dir) and mirror(dir) or dir
  local win, buf, job = float_job({ "glow", show }, show, dir, function(buf)
    if browsers[tab] and browsers[tab].buf == buf then
      browsers[tab] = nil
    end
  end)
  browsers[tab] = { win = win, buf = buf, job = job, dir = dir }
end

-- glow's ANSI output -> plain lines + highlight ranges, so it can live in a normal buffer.

local ansi_ns = vim.api.nvim_create_namespace("tools_glow_ansi")
local hl_cache = {}
local base16 = {
  "#000000", "#cd0000", "#00cd00", "#cdcd00", "#0000ee", "#cd00cd", "#00cdcd", "#e5e5e5",
  "#7f7f7f", "#ff0000", "#00ff00", "#ffff00", "#5c5cff", "#ff00ff", "#00ffff", "#ffffff",
}

local function xterm(n)
  if n < 16 then
    return base16[n + 1]
  elseif n < 232 then
    local lv = { 0, 95, 135, 175, 215, 255 }
    n = n - 16
    return ("#%02x%02x%02x"):format(lv[math.floor(n / 36) + 1], lv[math.floor(n / 6) % 6 + 1], lv[n % 6 + 1])
  end
  local g = 8 + 10 * (n - 232)
  return ("#%02x%02x%02x"):format(g, g, g)
end

local function group_for(st)
  local key = table.concat({ st.fg or "", st.bg or "", st.bold and "b" or "", st.italic and "i" or "",
    st.underline and "u" or "", st.strike and "s" or "", st.reverse and "r" or "" }, ",")
  if key == ",,,,,," then
    return nil
  end
  if not hl_cache[key] then
    local name = "GlowAnsi" .. vim.tbl_count(hl_cache)
    vim.api.nvim_set_hl(0, name, { fg = st.fg, bg = st.bg, bold = st.bold, italic = st.italic,
      underline = st.underline, strikethrough = st.strike, reverse = st.reverse })
    hl_cache[key] = name
  end
  return hl_cache[key]
end

-- Apply one SGR parameter list ("1;38;5;203") to the style `st`.
local function sgr(st, params)
  local p = {}
  for n in ((params == "" and "0" or params) .. ";"):gmatch("([^;]*);") do
    p[#p + 1] = tonumber(n) or 0
  end
  local i = 1
  while i <= #p do
    local c = p[i]
    if c == 0 then
      for k in pairs(st) do st[k] = nil end
    elseif c == 1 then st.bold = true
    elseif c == 3 then st.italic = true
    elseif c == 4 then st.underline = true
    elseif c == 7 then st.reverse = true
    elseif c == 9 then st.strike = true
    elseif c == 22 then st.bold = nil
    elseif c == 23 then st.italic = nil
    elseif c == 24 then st.underline = nil
    elseif c == 27 then st.reverse = nil
    elseif c == 29 then st.strike = nil
    elseif c >= 30 and c <= 37 then st.fg = xterm(c - 30)
    elseif c >= 90 and c <= 97 then st.fg = xterm(c - 90 + 8)
    elseif c == 39 then st.fg = nil
    elseif c >= 40 and c <= 47 then st.bg = xterm(c - 40)
    elseif c >= 100 and c <= 107 then st.bg = xterm(c - 100 + 8)
    elseif c == 49 then st.bg = nil
    elseif c == 38 or c == 48 then
      local which = c == 38 and "fg" or "bg"
      if p[i + 1] == 5 and p[i + 2] then
        st[which] = xterm(p[i + 2])
        i = i + 2
      elseif p[i + 1] == 2 and p[i + 4] then
        st[which] = ("#%02x%02x%02x"):format(p[i + 2], p[i + 3], p[i + 4])
        i = i + 4
      end
    end
    i = i + 1
  end
end

local function parse_ansi(text)
  text = text:gsub("\27%].-\27\\", ""):gsub("\27%].-\7", "") -- OSC (hyperlinks, titles)
  local lines, marks, st = {}, {}, {}
  for raw in (text .. "\n"):gmatch("(.-)\r?\n") do
    local row, out, pos = #lines, {}, 1
    local col = 0
    while true do
      local s1, e1, params, final = raw:find("\27%[([%d;?]*)(%a)", pos)
      local chunk = raw:sub(pos, (s1 or 0) - 1)
      if s1 == nil then
        chunk = raw:sub(pos)
      end
      if #chunk > 0 then
        local g = group_for(st)
        if g then
          marks[#marks + 1] = { row, col, col + #chunk, g }
        end
        out[#out + 1] = chunk
        col = col + #chunk
      end
      if not s1 then
        break
      end
      if final == "m" then
        sgr(st, params)
      end
      pos = e1 + 1
    end
    lines[#lines + 1] = table.concat(out)
  end
  if lines[#lines] == "" then
    lines[#lines] = nil
  end
  return lines, marks
end

--- Open the current buffer, rendered by glow, in a full-screen float. glow's output goes into
--- a normal buffer (colours kept), not glow's own pager: glow's pager has no way to scroll
--- back left (`h` and `Left` mean "back" there). Here lines do not wrap, so `h`/`l`, `zh`/`zl`,
--- the mouse wheel in both directions, `/` and visual copy all work as in any buffer.
--- Works for any path, also one in a hidden or git-ignored folder (for example `.planning/`).
--- Unsaved changes show too. `q` closes, `r` renders again, `w` toggles wide mode (wide tables
--- and code at full width, then scroll with `h`/`l` or the horizontal wheel).
function M.view()
  if vim.fn.executable("glow") == 0 then
    return vim.notify("glow: not found on PATH — run `brew install glow`", vim.log.levels.WARN)
  end
  local src = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(src)
  if file == "" or vim.bo[src].buftype ~= "" then
    return vim.notify("glow: this buffer has no file", vim.log.levels.WARN)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local cfg = full_size()
  cfg.style, cfg.border, cfg.zindex = "minimal", "none", 60
  local win = vim.api.nvim_open_win(buf, true, cfg)
  local wo = vim.wo[win]
  wo.wrap, wo.cursorline, wo.sidescrolloff = false, true, 0
  pcall(vim.api.nvim_buf_set_name, buf, "glow://" .. vim.fn.fnamemodify(file, ":~:."))

  local wide = false
  local gen = 0 -- only the newest render draws (resizes and `r`/`w` can overlap)
  local function render()
    if not (vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(src)) then
      return
    end
    gen = gen + 1
    local mine = gen
    -- glow reads stdin with "-", so unsaved changes show and no temp file is needed.
    local text = table.concat(vim.api.nvim_buf_get_lines(src, 0, -1, false), "\n")
    local style = vim.o.background == "light" and "light" or "dark"
    local width = math.max(20, vim.api.nvim_win_get_width(win) - 2)
    if wide then
      -- Wide mode: no squeeze of tables and code. Prose lines get long too; use h/l to scroll.
      for _, l in ipairs(vim.api.nvim_buf_get_lines(src, 0, -1, false)) do
        width = math.max(width, vim.fn.strdisplaywidth(l) + 8)
      end
      width = math.min(width, 1000)
    end
    vim.system({ "glow", "-s", style, "-w", tostring(width), "-" }, { stdin = text, text = true,
      cwd = vim.fs.dirname(file) }, vim.schedule_wrap(function(res)
      if not vim.api.nvim_buf_is_valid(buf) or mine ~= gen then
        return
      end
      if res.code ~= 0 then
        return vim.notify("glow: " .. vim.trim(res.stderr or ""), vim.log.levels.ERROR)
      end
      local lines, marks = parse_ansi(res.stdout or "")
      local cursor = vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_cursor(win)
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modifiable = false
      vim.api.nvim_buf_clear_namespace(buf, ansi_ns, 0, -1)
      for _, m in ipairs(marks) do
        pcall(vim.api.nvim_buf_set_extmark, buf, ansi_ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
      end
      if cursor then
        pcall(vim.api.nvim_win_set_cursor, win, { math.min(cursor[1], #lines), cursor[2] })
      end
    end))
  end

  floats[win] = render
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      floats[win] = nil
    end,
  })
  local function close()
    pcall(vim.api.nvim_win_close, win, true)
  end
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true, desc = "Close glow view" })
  vim.keymap.set("n", "r", render, { buffer = buf, nowait = true, desc = "Render glow view again" })
  vim.keymap.set("n", "w", function()
    wide = not wide
    render()
    vim.notify("glow: " .. (wide and "wide (tables and code at full width)" or "fit to window"))
  end, { buffer = buf, nowait = true, desc = "Toggle glow wide mode" })
  render()
end

-- Render again at the new width when a preview window changes size.
local resize_timer
vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
  group = vim.api.nvim_create_augroup("tools_glow_resize", { clear = true }),
  callback = function()
    for win in pairs(floats) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_config(win, full_size())
      end
    end
    if next(previews) == nil and next(floats) == nil then
      return
    end
    if resize_timer then
      resize_timer:stop()
    end
    resize_timer = vim.defer_fn(function()
      resize_timer = nil
      for _, f in pairs(floats) do
        if type(f) == "function" then
          f()
        end
      end
      for s, p in pairs(previews) do
        if valid_win(p) and p.width ~= vim.api.nvim_win_get_width(p.win) then
          p.width = vim.api.nvim_win_get_width(p.win)
          M.render(s)
        end
      end
    end, 150)
  end,
})

M._parse_ansi = parse_ansi -- for tests

return M
