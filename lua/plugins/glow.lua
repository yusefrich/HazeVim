-- Glow for Markdown (lua/tools/glow.lua). Needs the `glow` CLI (brew install glow).
-- Attached to the snacks spec, like worktree.lua, so no extra plugin is pulled in.
-- Made here, not in a snacks `init`: lazy keeps only one `init` per plugin, so specs that
-- share the snacks entry would drop each other's.
vim.api.nvim_create_user_command("Glow", function()
  require("tools.glow").browse()
end, { desc = "Glow start screen (Markdown files of this worktree), full screen" })

vim.api.nvim_create_user_command("GlowFile", function()
  require("tools.glow").view()
end, { desc = "Open the current buffer in glow, full screen" })

vim.api.nvim_create_user_command("GlowPreview", function()
  require("tools.glow").toggle()
end, { desc = "Toggle glow preview of the current Markdown file" })

return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>cg",
        function()
          require("tools.glow").browse()
        end,
        desc = "Glow (full screen)",
      },
      {
        "<leader>cG",
        function()
          require("tools.glow").view()
        end,
        desc = "Glow current buffer (full screen)",
      },
    },
  },
}
