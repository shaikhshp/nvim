local M = {}
local sources, pending = {}, {}
local busy, suspended = false, false
local excluded =
    { NvimTree = true, aerial = true, alpha = true, undotree = true, DiffviewFiles = true, DiffviewFileHistory = true }

function M.is_review_tab()
    return vim.t.user_diffview == true
end

local function eligible(win)
    if not win or not vim.api.nvim_win_is_valid(win) then
        return false
    end
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage()
        and vim.api.nvim_win_get_config(win).relative == ""
        and vim.bo[buf].buftype == ""
        and not excluded[vim.bo[buf].filetype]
        and not vim.wo[win].diff
end

function M.source_window()
    if suspended or M.is_review_tab() then
        return nil
    end
    local tab, current = vim.api.nvim_get_current_tabpage(), vim.api.nvim_get_current_win()
    if not busy and eligible(current) then
        sources[tab] = current
    end
    if eligible(sources[tab]) then
        return sources[tab]
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        if eligible(win) then
            sources[tab] = win
            return win
        end
    end
end

local function panels()
    local tree, outline
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_config(win).relative == "" then
            local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
            if ft == "NvimTree" then
                tree = win
            end
            if ft == "aerial" then
                outline = win
            end
        end
    end
    return tree, outline
end

local function stacked(layout, tree, outline)
    if layout[1] == "leaf" then
        return false
    end
    local children = layout[2]
    if
        layout[1] == "col"
        and #children == 2
        and children[1][1] == "leaf"
        and children[1][2] == tree
        and children[2][1] == "leaf"
        and children[2][2] == outline
    then
        return true
    end
    for _, child in ipairs(children) do
        if stacked(child, tree, outline) then
            return true
        end
    end
    return false
end

local function close_outline(win)
    local replacement
    -- Neovim cannot close its last window; leave a normal editor instead.
    if #vim.api.nvim_tabpage_list_wins(0) == 1 and #vim.api.nvim_list_tabpages() == 1 then
        replacement = vim.api.nvim_open_win(vim.api.nvim_create_buf(true, false), true, { split = "below", win = win })
        for _, option in ipairs({
            "list",
            "number",
            "relativenumber",
            "signcolumn",
            "foldcolumn",
            "wrap",
            "spell",
            "winfixwidth",
            "winfixheight",
        }) do
            vim.api.nvim_set_option_value(
                option,
                vim.api.nvim_get_option_value(option, { scope = "global" }),
                { win = replacement }
            )
        end
    end
    vim.api.nvim_win_close(win, true)
    return replacement
end

function M.reconcile()
    if busy or suspended or M.is_review_tab() then
        return
    end
    local tree, outline = panels()
    if not tree and not outline then
        return
    end
    local source, focus = M.source_window(), vim.api.nvim_get_current_win()
    busy = true
    local ok, err = pcall(function()
        if outline then
            if not source then
                focus = close_outline(outline) or focus
                outline = nil
            elseif
                vim.w[outline].source_win ~= source
                or vim.b[vim.api.nvim_win_get_buf(outline)].source_buffer ~= vim.api.nvim_win_get_buf(source)
            then
                require("aerial").open_in_win(outline, source)
            end
        end
        local anchor = tree or outline
        if not anchor then
            return
        end
        local correct = tree and outline and stacked(vim.fn.winlayout(), tree, outline)
        if vim.api.nvim_win_get_position(anchor)[2] ~= 0 or (tree and outline and not correct) then
            vim.api.nvim_win_call(anchor, function()
                vim.cmd("wincmd H")
            end)
            if tree and outline then
                assert(
                    vim.fn.win_splitmove(outline, tree, { vertical = false, rightbelow = true }) == 0,
                    "Unable to stack outline below file tree"
                )
            end
        end
        for _, win in ipairs({ tree or outline, tree and outline or nil }) do
            vim.wo[win].winfixwidth = true
            vim.wo[win].winfixheight = false
            local width = math.min(30, math.max(10, vim.o.columns - 20))
            if vim.api.nvim_win_get_width(win) ~= width then
                vim.api.nvim_win_set_width(win, width)
            end
        end
        require("user.undotree").resize()
    end)
    if vim.api.nvim_win_is_valid(focus) and vim.api.nvim_get_current_win() ~= focus then
        pcall(vim.api.nvim_set_current_win, focus)
    end
    busy = false
    if not ok then
        vim.notify("Sidebar: " .. tostring(err), vim.log.levels.WARN)
    end
end

local function schedule()
    if busy or suspended then
        return
    end
    local tab = vim.api.nvim_get_current_tabpage()
    if pending[tab] then
        return
    end
    pending[tab] = true
    vim.schedule(function()
        pending[tab] = nil
        if vim.api.nvim_tabpage_is_valid(tab) and vim.api.nvim_get_current_tabpage() == tab then
            M.reconcile()
        end
    end)
end

function M.tree_toggle()
    if M.is_review_tab() then
        vim.notify("Use <Space>gT for Diffview's file panel", vim.log.levels.INFO)
        return
    end
    M.source_window()
    local ok, api = pcall(require, "nvim-tree.api")
    if not ok then
        return
    end
    api.tree.toggle()
    M.reconcile()
end

function M.outline_open(focus)
    local source = M.source_window()
    local ok, aerial = pcall(require, "aerial")
    if not ok or not source then
        vim.notify("Outline requires Aerial and a visible source buffer", vim.log.levels.WARN)
        return
    end
    local tree, outline = panels()
    if not outline then
        if vim.o.columns < 45 or vim.api.nvim_win_get_height(tree or source) < 8 then
            vim.notify("Not enough room for the outline", vim.log.levels.WARN)
            return
        end
        busy = true
        local opened, err = pcall(function()
            if tree then
                vim.api.nvim_win_call(tree, function()
                    vim.cmd("belowright split")
                    outline = vim.api.nvim_get_current_win()
                end)
                aerial.open_in_win(outline, source)
            else
                vim.api.nvim_set_current_win(source)
                aerial.open({ focus = false, direction = "left" })
            end
        end)
        busy = false
        if not opened then
            if outline and vim.api.nvim_win_is_valid(outline) then
                pcall(vim.api.nvim_win_close, outline, true)
            end
            vim.api.nvim_set_current_win(source)
            vim.notify("Outline: " .. tostring(err), vim.log.levels.WARN)
            return
        end
    end
    M.reconcile()
    local _, visible = panels()
    if vim.api.nvim_win_is_valid(source) then
        vim.api.nvim_set_current_win(focus and visible or source)
    end
end

function M.outline_toggle()
    local _, outline = panels()
    if outline then
        local source = M.source_window()
        local ok, replacement = pcall(close_outline, outline)
        if not ok then
            vim.notify("Outline: " .. tostring(replacement), vim.log.levels.WARN)
        elseif source or replacement then
            vim.api.nvim_set_current_win(source or replacement)
        end
    else
        M.outline_open(false)
    end
end

function M.outline_move(next_symbol)
    local source = M.source_window()
    local ok, aerial = pcall(require, "aerial")
    if ok and source then
        vim.api.nvim_set_current_win(source)
        if next_symbol then
            aerial.next()
        else
            aerial.prev()
        end
    end
end

function M.resize()
    if M.is_review_tab() then
        return
    end
    local tree, outline = panels()
    local undo = false
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        undo = undo or vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "undotree"
    end
    if not tree and not outline and not undo then
        vim.cmd("wincmd =")
    end
    M.reconcile()
    require("user.undotree").resize()
end

function M.setup()
    local group = vim.api.nvim_create_augroup("UserSidebar", { clear = true })
    vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
        group = group,
        callback = function()
            if not busy then
                local source = M.source_window()
                if source == vim.api.nvim_get_current_win() then
                    schedule()
                end
            end
        end,
    })
    vim.api.nvim_create_autocmd(
        { "BufWinEnter", "WinNew", "WinClosed", "TabEnter", "VimResized" },
        { group = group, callback = schedule }
    )
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "PersistenceLoadPre",
        callback = function()
            suspended = true
            sources = {}
        end,
    })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "PersistenceLoadPost",
        callback = function()
            suspended = false
            M.source_window()
            schedule()
        end,
    })
    local ok, api = pcall(require, "nvim-tree.api")
    if ok then
        api.events.subscribe(api.events.Event.TreeOpen, schedule)
        api.events.subscribe(api.events.Event.TreeClose, schedule)
    end
    M.source_window()
end

return M
