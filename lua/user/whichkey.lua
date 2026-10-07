local ok, which_key = pcall(require, "which-key")
if not ok then
    return
end
which_key.setup({
    win = { border = "rounded", padding = { 1, 2 } },
    plugins = { spelling = { enabled = true, suggestions = 20 } },
})
which_key.add({
    { "<leader>A", group = "Local AI" },
    { "<leader>p", group = "Plugins" },
    { "<leader>g", group = "Git" },
    { "<leader>o", group = "Outline" },
    { "<leader>U", group = "Undo history" },
    { "<leader>l", group = "Language" },
    { "<leader>s", group = "Search" },
    { "<leader>t", group = "Terminals" },
    { "<leader>d", group = "Debug" },
    { "<leader>x", group = "LaTeX" },
    { "<leader>v", group = "VimTeX defaults" },
    { "<leader>j", group = "Java" },
    { "<leader>R", group = "Rust" },
    { "<leader>m", group = "Notebook" },
})
