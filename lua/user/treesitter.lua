local M = {}

local status_ok, treesitter = pcall(require, "nvim-treesitter")
if not status_ok then
    return M
end

M.parsers = {
    "python",
    "latex",
    "rust",
    "java",
    "lua",
    "bash",
    "markdown",
    "markdown_inline",
    "json",
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
}

local function start(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
        return
    end

    local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
    if not lang or not vim.tbl_contains(M.parsers, lang) then
        return
    end

    local ready, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
    if not ready or not parser then
        return
    end

    if lang ~= "css" then
        pcall(vim.treesitter.start, bufnr, lang)
    end
    -- Keep native indentation where it is preferred or no indent query exists.
    if lang ~= "python" and lang ~= "css" then
        local ok, query = pcall(vim.treesitter.query.get, lang, "indents")
        if ok and query then
            vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end
end

function M.config()
    treesitter.setup({})
    vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
        group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
        callback = function(args)
            start(args.buf)
        end,
    })

    local autotag_ok, autotag = pcall(require, "nvim-ts-autotag")
    if autotag_ok then
        autotag.setup({})
    end
    start(vim.api.nvim_get_current_buf())
end

-- Opt in from main integration; requiring this module never installs parsers.
function M.install()
    local task = treesitter.install(M.parsers)
    task:await(function()
        vim.schedule(function()
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(bufnr) then
                    start(bufnr)
                end
            end
        end)
    end)
    return task
end

M.config()

return M
