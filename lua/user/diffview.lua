local status_ok, diffview = pcall(require, "diffview")
if not status_ok then
    return
end

local actions = require("diffview.actions")
local opening = setmetatable({}, { __mode = "k" })

diffview.setup({
    view = {
        default = { layout = "diff2_horizontal", disable_diagnostics = false },
        file_history = { layout = "diff2_horizontal", disable_diagnostics = false },
        merge_tool = { disable_diagnostics = true },
    },
    file_panel = { win_config = { position = "left", width = 30 } },
    file_history_panel = { win_config = { position = "bottom", height = 12 } },
    hooks = {
        view_opened = function(view)
            view.emitter:on("file_open_pre", function()
                opening[view] = (opening[view] or 0) + 1
            end)
            view.emitter:on("file_open_post", function()
                opening[view] = math.max(0, (opening[view] or 0) - 1)
            end)
            if view.tabpage and vim.api.nvim_tabpage_is_valid(view.tabpage) then
                vim.api.nvim_tabpage_set_var(view.tabpage, "user_diffview", true)
            end
        end,
        view_closed = function(view)
            opening[view] = nil
            if view.tabpage and vim.api.nvim_tabpage_is_valid(view.tabpage) then
                vim.api.nvim_tabpage_set_var(view.tabpage, "user_diffview", false)
            end
        end,
    },
    keymaps = {
        -- Explicit review actions only: no staging, restoration, or merge resolution.
        disable_defaults = true,
        view = {
            { "n", "<Tab>", actions.select_next_entry, { desc = "Open next diff" } },
            { "n", "<S-Tab>", actions.select_prev_entry, { desc = "Open previous diff" } },
            { "n", "gf", actions.goto_file_edit, { desc = "Open file in editor tab" } },
            { "n", "<C-w>gf", actions.goto_file_tab, { desc = "Open file in new tab" } },
            { "n", "<leader>gE", actions.focus_files, { desc = "Focus review files" } },
            { "n", "<leader>gT", actions.toggle_files, { desc = "Toggle review files" } },
            { "n", "g<C-x>", actions.cycle_layout, { desc = "Cycle diff layout" } },
            { "n", "g?", actions.help("view"), { desc = "Open the help panel" } },
        },
        file_panel = {
            { "n", "j", actions.next_entry, { desc = "Next file entry" } },
            { "n", "k", actions.prev_entry, { desc = "Previous file entry" } },
            { "n", "<CR>", actions.select_entry, { desc = "Open selected diff" } },
            { "n", "o", actions.select_entry, { desc = "Open selected diff" } },
            { "n", "<Tab>", actions.select_next_entry, { desc = "Open next diff" } },
            { "n", "<S-Tab>", actions.select_prev_entry, { desc = "Open previous diff" } },
            { "n", "gf", actions.goto_file_edit, { desc = "Open file in editor tab" } },
            { "n", "<C-w>gf", actions.goto_file_tab, { desc = "Open file in new tab" } },
            { "n", "za", actions.toggle_fold, { desc = "Toggle directory fold" } },
            { "n", "R", actions.refresh_files, { desc = "Refresh review files" } },
            { "n", "<leader>gE", actions.focus_files, { desc = "Focus review files" } },
            { "n", "<leader>gT", actions.toggle_files, { desc = "Toggle review files" } },
            { "n", "g<C-x>", actions.cycle_layout, { desc = "Cycle diff layout" } },
            { "n", "g?", actions.help("file_panel"), { desc = "Open the help panel" } },
        },
        file_history_panel = {
            { "n", "j", actions.next_entry, { desc = "Next history entry" } },
            { "n", "k", actions.prev_entry, { desc = "Previous history entry" } },
            { "n", "<CR>", actions.select_entry, { desc = "Open selected history diff" } },
            { "n", "o", actions.select_entry, { desc = "Open selected history diff" } },
            { "n", "<Tab>", actions.select_next_entry, { desc = "Open next history diff" } },
            { "n", "<S-Tab>", actions.select_prev_entry, { desc = "Open previous history diff" } },
            { "n", "gf", actions.goto_file_edit, { desc = "Open file in editor tab" } },
            { "n", "<C-w>gf", actions.goto_file_tab, { desc = "Open file in new tab" } },
            { "n", "za", actions.toggle_fold, { desc = "Toggle commit fold" } },
            { "n", "y", actions.copy_hash, { desc = "Copy commit hash" } },
            { "n", "L", actions.open_commit_log, { desc = "Show commit details" } },
            { "n", "g!", actions.options, { desc = "Open history options" } },
            { "n", "<leader>gE", actions.focus_files, { desc = "Focus review files" } },
            { "n", "<leader>gT", actions.toggle_files, { desc = "Toggle review files" } },
            { "n", "g<C-x>", actions.cycle_layout, { desc = "Cycle diff layout" } },
            { "n", "g?", actions.help("file_history_panel"), { desc = "Open the help panel" } },
        },
        option_panel = {
            { "n", "<Tab>", actions.select_entry, { desc = "Change history option" } },
            { "n", "q", actions.close, { desc = "Close options" } },
            { "n", "g?", actions.help("option_panel"), { desc = "Open the help panel" } },
        },
        help_panel = {
            { "n", "q", actions.close, { desc = "Close help" } },
            { "n", "<Esc>", actions.close, { desc = "Close help" } },
        },
    },
})

local function open_review(history, current_file)
    local win = require("user.sidebar").source_window()
    local name
    if win and vim.api.nvim_win_is_valid(win) then
        local buf = vim.api.nvim_win_get_buf(win)
        name = vim.api.nvim_buf_get_name(buf)
        if
            vim.api.nvim_win_get_tabpage(win) ~= vim.api.nvim_get_current_tabpage()
            or vim.api.nvim_win_get_config(win).relative ~= ""
            or vim.wo[win].diff
            or vim.bo[buf].buftype ~= ""
            or name == ""
            or name:match("^%a[%w+.-]*://")
            or vim.fn.isdirectory(name) == 1
        then
            name = nil
        end
    end
    if current_file and not name then
        vim.notify("Diffview requires a normal source filename", vim.log.levels.WARN)
        return
    end
    if not history and current_file and name:match("%.ipynb$") then
        vim.notify(
            "Notebook buffers display Python, not Git JSON; use history or a notebook-aware diff tool",
            vim.log.levels.WARN
        )
        return
    end

    local args = history and {} or { "HEAD" }
    if not history and not current_file then
        args[#args + 1] = "--"
        args[#args + 1] = ":(exclude,glob)**/*.ipynb"
    end
    if name then
        -- Keep source-local cwd/repository discovery, without changing its sidebars.
        vim.api.nvim_set_current_win(win)
        if current_file then
            if not history then
                args[#args + 1] = "--"
            end
            args[#args + 1] = name
        end
    else
        -- Explicit cwd avoids discovering a repository from a utility/revision buffer.
        table.insert(args, 1, "-C" .. vim.fn.getcwd())
    end
    if history then
        diffview.file_history(nil, args)
    else
        diffview.open(args)
    end
end

vim.keymap.set("n", "<leader>gD", function()
    open_review(false, false)
end, { desc = "Review project against HEAD" })
vim.keymap.set("n", "<leader>gF", function()
    open_review(false, true)
end, { desc = "Review source file against HEAD" })
vim.keymap.set("n", "<leader>gh", function()
    open_review(true, true)
end, { desc = "Review source file history" })
vim.keymap.set("n", "<leader>gH", function()
    open_review(true, false)
end, { desc = "Review project history" })
vim.keymap.set("n", "<leader>gQ", function()
    local view = require("diffview.lib").get_current_view()
    -- This pinned release can resume a file-open callback after an early close.
    if
        view
        and (
            not view.ready
            or view.panel.updating
            or (opening[view] or 0) > 0
            or (view.cur_entry and (not view.cur_entry.opened or not view.cur_layout:is_files_loaded()))
        )
    then
        vim.notify("Diffview is still opening revision content; retry close when loaded", vim.log.levels.INFO)
        return
    end
    diffview.close()
end, { desc = "Close Diffview review" })
