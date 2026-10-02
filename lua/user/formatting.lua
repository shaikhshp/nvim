local M = {}
local ok, conform = pcall(require, "conform")
local preferred = { python = "ruff", rust = "rust_analyzer", java = "jdtls", tex = "texlab", bib = "texlab" }

function M.eligible(bufnr)
    local opts = vim.bo[bufnr]
    return opts.buftype == ""
        and opts.modifiable
        and not opts.readonly
        and not vim.api.nvim_buf_get_name(bufnr):match("%.ipynb$")
        and vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr)) <= 1024 * 1024
end

local function options(bufnr)
    local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" })
    table.sort(clients, function(a, b)
        local name = preferred[vim.bo[bufnr].filetype]
        if (a.name == name) ~= (b.name == name) then
            return a.name == name
        end
        return a.id < b.id
    end)
    local id = clients[1] and clients[1].id
    return {
        bufnr = bufnr,
        async = false,
        timeout_ms = 2000,
        lsp_format = "fallback",
        stop_after_first = true,
        filter = function(client)
            return client.id == id
        end,
    }
end

function M.format(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if not M.eligible(bufnr) then
        return false
    end
    if ok then
        return conform.format(options(bufnr))
    end
    if #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" }) > 0 then
        vim.lsp.buf.format(options(bufnr))
        return true
    end
    return false
end

function M.toggle(global)
    if global then
        vim.g.disable_autoformat = not vim.g.disable_autoformat
    else
        vim.b.disable_autoformat = not vim.b.disable_autoformat
    end
    local disabled
    if global then
        disabled = vim.g.disable_autoformat
    else
        disabled = vim.b.disable_autoformat
    end
    vim.notify((global and "Global" or "Buffer") .. " format-on-save " .. (disabled and "disabled" or "enabled"))
end

if ok then
    conform.setup({
        notify_on_error = true,
        notify_no_formatters = false,
        default_format_opts = { lsp_format = "fallback", stop_after_first = true, timeout_ms = 2000 },
        formatters_by_ft = {
            python = { "ruff_format", "black", stop_after_first = true },
            rust = { "rustfmt" },
            tex = { "latexindent" },
            plaintex = { "latexindent" },
            bib = { "latexindent" },
            lua = { "stylua" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            javascript = { "prettierd", "prettier", stop_after_first = true },
            javascriptreact = { "prettierd", "prettier", stop_after_first = true },
            typescript = { "prettierd", "prettier", stop_after_first = true },
            typescriptreact = { "prettierd", "prettier", stop_after_first = true },
            json = { "prettier" },
            jsonc = { "prettier" },
            html = { "prettier" },
            css = { "prettier" },
            markdown = { "prettier" },
            yaml = { "prettier" },
            c = { "clang_format" },
            cpp = { "clang_format" },
        },
    })
end

vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("UserFormatting", { clear = true }),
    callback = function(event)
        if not vim.g.disable_autoformat and not vim.b[event.buf].disable_autoformat then
            local success, err = pcall(M.format, event.buf)
            if not success then
                vim.notify("Formatting failed: " .. tostring(err), vim.log.levels.ERROR)
            end
        end
    end,
})
vim.api.nvim_create_user_command("FormatToggle", function(args)
    M.toggle(args.bang)
end, {
    bang = true,
    desc = "Toggle buffer format-on-save; ! toggles globally",
})
return M
