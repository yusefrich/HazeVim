-- ~/.config/nvim/lua/plugins/diffview.lua
-- Manual "Claude changes" review view. NOT auto-opened on startup -- nvim opens normally.
-- Open/close with the :ClaudeChanges command or <leader>gC (a toggle). `q` inside the
-- view also closes it.
local function toggle_changes()
  local ok, lib = pcall(require, "diffview.lib")
  if ok and lib.get_current_view() then
    vim.cmd("DiffviewClose")
  else
    vim.cmd("DiffviewOpen")
  end
end

return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
  keys = {
    { "<leader>gC", toggle_changes, desc = "Claude changes: toggle diff view" },
  },
  init = function()
    -- Per request: only add the command if it isn't already taken; otherwise keep theirs.
    if vim.fn.exists(":ClaudeChanges") == 0 then
      vim.api.nvim_create_user_command("ClaudeChanges", toggle_changes,
        { desc = "Toggle the Claude changes (diffview) view" })
    else
      vim.schedule(function()
        vim.notify(":ClaudeChanges already exists -- keeping the existing command", vim.log.levels.WARN)
      end)
    end
  end,
  opts = {
    enhanced_diff_hl = true,
    view = { default = { layout = "diff2_horizontal" } },
  },
}
