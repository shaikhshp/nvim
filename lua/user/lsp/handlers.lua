local M = {}

M.capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, cmp = pcall(require, "cmp_nvim_lsp")
if ok then
    M.capabilities = cmp.default_capabilities(M.capabilities)
end

function M.setup()
    vim.diagnostic.config({
        virtual_text = false,
        signs = true,
        update_in_insert = true,
        underline = true,
        severity_sort = true,
        float = { border = "rounded", source = "always", header = "", prefix = "" },
    })
end

function M.on_attach(client, bufnr)
    if client.name == "ruff" then
        client.server_capabilities.hoverProvider = false
    end
    local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end
    map("gD", vim.lsp.buf.declaration, "LSP declaration")
    map("gd", vim.lsp.buf.definition, "LSP definition")
    map("K", function()
        vim.lsp.buf.hover({ border = "rounded" })
    end, "LSP hover")
    map("gI", vim.lsp.buf.implementation, "LSP implementation")
    map("grr", vim.lsp.buf.references, "LSP references")
    map("gl", vim.diagnostic.open_float, "Line diagnostics")
    map("<leader>lf", function()
        require("user.formatting").format()
    end, "Format buffer")
    map("<leader>li", "<cmd>LspInfo<CR>", "LSP information")
    map("<leader>lm", "<cmd>Mason<CR>", "Mason tools")
    map("<leader>la", vim.lsp.buf.code_action, "LSP code action")
    map("<leader>lj", function()
        vim.diagnostic.jump({ count = 1, float = true })
    end, "Next diagnostic")
    map("<leader>lk", function()
        vim.diagnostic.jump({ count = -1, float = true })
    end, "Previous diagnostic")
    map("<leader>lr", vim.lsp.buf.rename, "LSP rename")
    map("<leader>ls", "<cmd>Telescope lsp_document_symbols<CR>", "Document symbols")
    map("<leader>lh", function()
        vim.lsp.buf.signature_help({ border = "rounded" })
    end, "Signature help")
    map("<leader>lq", vim.diagnostic.setloclist, "Diagnostic location list")
end

return M
