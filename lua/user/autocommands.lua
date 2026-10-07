local group = vim.api.nvim_create_augroup("UserEditor", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "qf", "help", "man", "lspinfo" },
    callback = function(event)
        vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true, desc = "Close utility window" })
        if vim.bo[event.buf].filetype == "qf" then
            vim.bo[event.buf].buflisted = false
        end
    end,
})
vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    callback = function()
        vim.hl.on_yank({ higroup = "Visual", timeout = 200 })
    end,
})
vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function()
        vim.opt_local.formatoptions:remove({ "c", "r", "o" })
    end,
})
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "markdown", "gitcommit" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})
vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
        local current = vim.api.nvim_get_current_tabpage()
        for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
            vim.api.nvim_set_current_tabpage(tab)
            require("user.sidebar").resize()
        end
        vim.api.nvim_set_current_tabpage(current)
    end,
})
vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
        vim.opt.showtabline = vim.bo.filetype == "alpha" and 0 or 2
    end,
})
