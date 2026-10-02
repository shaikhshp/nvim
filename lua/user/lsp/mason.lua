local M = {}

M.servers = {
    "lua_ls",
    "cssls",
    "html",
    "ts_ls",
    "pyright",
    "ruff",
    "bashls",
    "jsonls",
    "clangd",
    "grammarly",
    "marksman",
    "eslint",
    "texlab",
    "rust_analyzer",
}
M.tools = {
    "jdtls",
    "debugpy",
    "codelldb",
    "java-debug-adapter",
    "java-test",
    "ruff",
    "latexindent",
    "stylua",
    "shfmt",
    "prettier",
    "tree-sitter-cli",
}

function M.enable_available()
    if not vim.lsp.config or not vim.lsp.enable then
        return
    end
    for _, server in ipairs(M.servers) do
        local config = vim.lsp.config[server]
        if config and (type(config.cmd) == "function" or (config.cmd and vim.fn.executable(config.cmd[1]) == 1)) then
            vim.lsp.enable(server)
        end
    end
end

-- Deliberately opt-in: startup configures tools but never installs them.
function M.provision(opts)
    opts = opts or {}
    local ok, registry = pcall(require, "mason-registry")
    if not ok then
        vim.notify("Mason is unavailable", vim.log.levels.WARN)
        return
    end
    registry.refresh(function()
        local names = vim.deepcopy(M.tools)
        local mappings = require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package
        for _, server in ipairs(M.servers) do
            if mappings[server] then
                names[#names + 1] = mappings[server]
            end
        end
        if opts.black then
            names[#names + 1] = "black"
        end
        local seen = {}
        for _, name in ipairs(names) do
            if not seen[name] then
                seen[name] = true
                local found, package = pcall(registry.get_package, name)
                if found and not package:is_installed() and not package:is_installing() then
                    package:once("install:success", vim.schedule_wrap(M.enable_available))
                    package:install()
                elseif not found then
                    vim.schedule(function()
                        vim.notify("Mason package unavailable: " .. name, vim.log.levels.WARN)
                    end)
                end
            end
        end
        vim.schedule(M.enable_available)
    end)
end

local mason_ok, mason = pcall(require, "mason")
local lsp_ok, mason_lsp = pcall(require, "mason-lspconfig")
if not mason_ok or not lsp_ok or not vim.lsp.config or not vim.lsp.enable then
    return M
end

mason.setup({ ui = { border = "none" }, max_concurrent_installers = 4 })
mason_lsp.setup({ ensure_installed = {}, automatic_enable = false })

local handlers = require("user.lsp.handlers")
for _, server in ipairs(M.servers) do
    local default = vim.lsp.config[server] or {}
    local settings_ok, settings = pcall(require, "user.lsp.settings." .. server)
    local opts = settings_ok and settings or {}
    local attach = opts.on_attach or default.on_attach
    opts.on_attach = function(client, bufnr)
        if attach then
            attach(client, bufnr)
        end
        handlers.on_attach(client, bufnr)
    end
    opts.capabilities =
        vim.tbl_deep_extend("force", default.capabilities or {}, handlers.capabilities, opts.capabilities or {})
    vim.lsp.config(server, opts)
end
M.enable_available()

return M
