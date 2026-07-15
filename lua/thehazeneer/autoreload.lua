-- ~/.config/nvim/lua/thehazeneer/autoreload.lua
-- Passive on-disk reflection: when Claude Code (running in another Ghostty pane)
-- rewrites a file, reload the buffer with NO prompt and let gitsigns highlight the
-- change. Nothing here can pause or gate Claude.

local M = {}

vim.o.autoread = true

local group = vim.api.nvim_create_augroup("thehazeneer_autoreload", { clear = true })

-- Safe to run :checktime now? Avoid cmdline/prompt (E523) and completion popup.
local function safe_to_check()
  local mode = vim.fn.mode()
  if mode == "c" or mode == "r" or mode == "rm" or mode == "r?" or mode == "!" then
    return false
  end
  if vim.fn.pumvisible() == 1 then
    return false
  end
  return true
end

local function do_checktime()
  if not safe_to_check() then
    return
  end
  pcall(vim.cmd, "checktime")
end

-- (a) refocus / buffer-enter triggers
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  group = group,
  callback = do_checktime,
})

-- (b) LIVE poll while pane is visible but unfocused
if _G.__thehazeneer_autoreload_timer then
  pcall(function()
    _G.__thehazeneer_autoreload_timer:stop()
    _G.__thehazeneer_autoreload_timer:close()
  end)
  _G.__thehazeneer_autoreload_timer = nil
end
local timer = vim.uv.new_timer()
_G.__thehazeneer_autoreload_timer = timer
timer:start(1000, 1000, vim.schedule_wrap(do_checktime))

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = function()
    if _G.__thehazeneer_autoreload_timer then
      pcall(function()
        _G.__thehazeneer_autoreload_timer:stop()
        _G.__thehazeneer_autoreload_timer:close()
      end)
      _G.__thehazeneer_autoreload_timer = nil
    end
  end,
})

local function notify(msg, level)
  if _G.Snacks and Snacks.notify then
    Snacks.notify(msg, { title = "autoreload", level = level or "info" })
  else
    vim.notify(msg, vim.log.levels[(level or "info"):upper()] or vim.log.levels.INFO)
  end
end

-- Defining FileChangedShell overrides autoread's silent reload -> WE decide.
vim.api.nvim_create_autocmd("FileChangedShell", {
  group = group,
  callback = function(args)
    local reason = vim.v.fcs_reason
    if reason == "conflict" or reason == "deleted" then
      vim.v.fcs_choice = "" -- keep user's buffer, do NOT clobber unsaved edits
      local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":t")
      local msg = reason == "deleted"
          and ("\u{26A0} " .. name .. " was deleted on disk (buffer kept)")
          or ("\u{26A0} " .. name .. " changed on disk but has UNSAVED edits \u{2014} not reloaded")
      vim.schedule(function() notify(msg, "warn") end)
    elseif reason == "time" then
      vim.v.fcs_choice = "" -- only mtime touched, nothing to reload
    else -- "changed"/"mode": buffer unmodified, reflect the disk edit
      vim.v.fcs_choice = "reload"
    end
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = group,
  callback = function(args)
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":t")
    notify("\u{21BB} reloaded " .. name .. " (external change)", "info")
  end,
})

return M
