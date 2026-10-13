local M = {}

function M.eligible(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
        return false
    end
    local name = vim.api.nvim_buf_get_name(bufnr)
    if
        vim.bo[bufnr].buftype ~= ""
        or name == ""
        or name:match("^%a[%w+.-]*://")
        or name:match("^untitled:")
        or vim.fs.basename(name):match("^untitled:")
    then
        return false
    end
    local resolved = vim.uv.fs_realpath(name)
    if name:lower():match("%.ipynb$") or (resolved and resolved:lower():match("%.ipynb$")) then
        return false
    end
    return vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr)) <= 1024 * 1024
end

function M.root_dir(bufnr, on_dir, markers)
    if M.eligible(bufnr) then
        on_dir(vim.fs.root(bufnr, markers) or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
    end
end

function M.on_attach(client, bufnr)
    for _, is_pull in ipairs({ false, true }) do
        vim.diagnostic.config({
            signs = false,
            virtual_text = false,
            update_in_insert = false,
        }, vim.lsp.diagnostic.get_namespace(client.id, is_pull))
    end
end

return M
