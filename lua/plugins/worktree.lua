-- Keymaps for lua/tools/worktree.lua. Attached to the snacks spec so lazy owns the
-- lazy-loading and no extra plugin is pulled in.
-- Made here, not in a snacks `init`: lazy keeps only one `init` per plugin, so specs that
-- share the snacks entry would drop each other's.
vim.api.nvim_create_user_command("Worktrees", function()
  require("tools.worktree").browse()
end, { desc = "Switch git worktree" })

return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>gW",
        function()
          require("tools.worktree").browse()
        end,
        desc = "Switch git worktree",
      },
      {
        "<leader>gD",
        function()
          require("tools.worktree").diff_trunk()
        end,
        desc = "Diff worktree vs trunk",
      },
    },
  },
}
