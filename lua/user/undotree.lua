local M = {}
local resizing = false

function M.init()
    vim.g.undotree_CustomUndotreeCmd = "botright 12new"
    vim.g.undotree_CustomDiffpanelCmd = "belowright vertical 60new"
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.g.undotree_DiffAutoOpen = 0
    vim.g.undotree_ShortIndicators = 1
    vim.g.undotree_HighlightChangedWithSign = 0
end

function M.resize()
    if resizing then
        return
    end
    resizing = true
    local focus = vim.api.nvim_get_current_win()
    local ok, err = pcall(function()
        local undo, diff
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype
            local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
            if vim.api.nvim_win_get_config(win).relative == "" and vim.b[buf].isUndotreeBuffer == 1 then
                if ft == "undotree" and name:match("^undotree_%d+$") then
                    undo = win
                elseif ft == "diff" and name:match("^diffpanel_%d+$") then
                    diff = win
                end
            end
        end
        if not undo then
            return
        end

        local layout = vim.fn.winlayout()
        local bottom = layout[1] == "col" and layout[2][#layout[2]] or nil
        local correct = bottom and bottom[1] == "leaf" and bottom[2] == undo and not diff
        if diff and bottom and bottom[1] == "row" and #bottom[2] == 2 then
            local left, right = bottom[2][1], bottom[2][2]
            correct = left[1] == "leaf" and left[2] == undo and right[1] == "leaf" and right[2] == diff
        end
        if not correct then
            -- A newly opened topleft sidebar must not claim the bottom row.
            vim.api.nvim_win_call(undo, function()
                vim.cmd("wincmd J")
            end)
            if diff then
                vim.fn.win_splitmove(diff, undo, { vertical = true, rightbelow = true })
            end
        end

        local height = math.max(1, math.min(12, math.floor(vim.o.lines / 3)))
        for _, win in ipairs(diff and { undo, diff } or { undo }) do
            vim.wo[win].winfixheight = true
            vim.wo[win].winfixwidth = false
            if vim.api.nvim_win_get_height(win) ~= height then
                vim.api.nvim_win_set_height(win, height)
            end
        end
    end)
    if vim.api.nvim_win_is_valid(focus) and vim.api.nvim_get_current_win() ~= focus then
        pcall(vim.api.nvim_set_current_win, focus)
    end
    resizing = false
    if not ok then
        vim.notify("Undotree layout: " .. tostring(err), vim.log.levels.WARN)
    end
end

local function open_tree(toggle)
    local command = toggle and "UndotreeToggle" or "UndotreeShow"
    if vim.fn.exists(":" .. command) ~= 2 then
        vim.notify("Undotree is not installed or loaded", vim.log.levels.WARN)
        return
    end

    local win = require("user.sidebar").source_window()
    if not win or not vim.api.nvim_win_is_valid(win) then
        vim.notify("Undotree requires a visible source file", vim.log.levels.WARN)
        return
    end

    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if
        vim.api.nvim_win_get_tabpage(win) ~= vim.api.nvim_get_current_tabpage()
        or vim.api.nvim_win_get_config(win).relative ~= ""
        or vim.wo[win].diff
        or vim.bo[buf].buftype ~= ""
        or not vim.bo[buf].modifiable
        or vim.bo[buf].readonly
        or name == ""
        or name:match("^%a[%w+.-]*://")
        or vim.fn.isdirectory(name) == 1
    then
        vim.notify("Undotree requires a normal editable source file", vim.log.levels.WARN)
        return
    end

    local focus
    local ok, err = pcall(vim.api.nvim_win_call, win, function()
        -- Refresh an already-visible tree's target before focusing it.
        if vim.fn.exists("*undotree#UndotreeUpdate") == 1 then
            vim.fn["undotree#UndotreeUpdate"]()
        end
        vim.api.nvim_cmd({ cmd = command }, {})
        focus = vim.api.nvim_get_current_win()
    end)
    if not ok then
        vim.notify("Undotree: " .. tostring(err), vim.log.levels.WARN)
        return
    end

    -- nvim_win_call restores the caller; honor the plugin's requested focus.
    if focus and vim.api.nvim_win_is_valid(focus) then
        vim.api.nvim_set_current_win(focus)
    end
    M.resize()
end

function M.setup()
    vim.keymap.set("n", "<leader>Ut", function()
        open_tree(true)
    end, { desc = "Toggle source undo tree" })
    vim.keymap.set("n", "<leader>Uf", function()
        open_tree(false)
    end, { desc = "Open or focus source undo tree" })

    local group = vim.api.nvim_create_augroup("UserUndotree", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "undotree", "diff" },
        callback = function(event)
            if vim.bo[event.buf].filetype == "undotree" then
                vim.wo.winfixheight = true
                vim.wo.winfixwidth = false
            end
            M.resize()
        end,
    })
    vim.api.nvim_create_autocmd("VimResized", {
        group = group,
        callback = M.resize,
    })
end

return M
