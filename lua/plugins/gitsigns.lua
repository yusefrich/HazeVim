-- ~/.config/nvim/lua/plugins/gitsigns.lua
return {
  "lewis6991/gitsigns.nvim",
  opts = {
    signcolumn = true,
    numhl = false,
    linehl = false,
    word_diff = false,
    watch_gitdir = { follow_files = true },
  },
  keys = {
    { "<leader>uhl", function() require("gitsigns").toggle_linehl() end,       desc = "Git: toggle line highlight" },
    { "<leader>uhw", function() require("gitsigns").toggle_word_diff() end,    desc = "Git: toggle word diff" },
    { "<leader>uhn", function() require("gitsigns").toggle_numhl() end,        desc = "Git: toggle number highlight" },
    { "<leader>uhd", function() require("gitsigns").toggle_deleted() end,      desc = "Git: toggle deleted lines" },
    { "<leader>uhi", function() require("gitsigns").preview_hunk_inline() end, desc = "Git: preview hunk inline" },
  },
}
