vim.g.mkdp_filetypes = { "markdown" }
vim.g.mkdp_echo_preview_url = 1

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("UserMarkdownPreview", { clear = true }),
    pattern = "markdown",
    callback = function(event)
        vim.keymap.set("n", "<leader>Mp", "<cmd>MarkdownPreviewToggle<CR>", {
            buffer = event.buf,
            silent = true,
            desc = "Toggle Markdown browser preview",
        })
        vim.keymap.set("n", "<leader>Ms", "<cmd>MarkdownPreviewStop<CR>", {
            buffer = event.buf,
            silent = true,
            desc = "Stop Markdown browser preview",
        })
    end,
})

local ok, glow = pcall(require, "glow")
if ok then
    glow.setup({})
end
