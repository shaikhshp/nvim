local ok, aerial = pcall(require, "aerial")
if not ok then
    return
end

aerial.setup({
    attach_mode = "global",
    open_automatic = false,
    manage_folds = false,
    link_folds_to_tree = false,
    link_tree_to_folds = false,
    show_guides = true,
    close_automatic_events = {},
    layout = {
        default_direction = "left",
        placement = "edge",
        width = 30,
        min_width = 30,
        max_width = 30,
        resize_to_content = false,
        preserve_equality = false,
        win_opts = { winfixwidth = true, winfixheight = false },
    },
    ignore = {
        filetypes = { "NvimTree", "alpha", "undotree", "DiffviewFiles", "DiffviewFileHistory" },
        buftypes = "special",
        wintypes = "special",
        diff_windows = true,
    },
    keymaps = { ["<C-j>"] = false, ["<C-k>"] = false },
})
