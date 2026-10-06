local status_ok, indent_blankline = pcall(require, "indent_blankline")
if not status_ok then
    return
end

-- Retain the pinned plugin's colorcolumn rendering workaround.
vim.wo.colorcolumn = "99999"

indent_blankline.setup({
    char = "▏",
    buftype_exclude = { "terminal", "nofile" },
    filetype_exclude = {
        "help",
        "startify",
        "dashboard",
        "lazy",
        "neogitstatus",
        "NvimTree",
        "Trouble",
    },
    show_trailing_blankline_indent = false,
    show_first_indent_level = true,
    use_treesitter = false,
    show_current_context = false,
})
