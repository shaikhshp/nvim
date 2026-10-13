-- Run: nvim --headless -u NONE -i NONE -l tests/spelling_config.lua
vim.opt.runtimepath:append(vim.fn.getcwd())
local process_calls = 0
local function no_process()
    process_calls = process_calls + 1
    error("spelling configuration must not start processes or requests")
end
vim.system = no_process
vim.fn.jobstart = no_process
vim.fn.system = no_process
vim.fn.systemlist = no_process
vim.lsp.start = no_process
vim.lsp.rpc.start = no_process
local spelling = require("user.spelling")
local harper = require("user.lsp.settings.harper_ls")
local typos = require("user.lsp.settings.typos_lsp")

local seen = {}
for _, config in ipairs({ harper, typos }) do
    assert(type(config.on_attach) == "function" and config.capabilities == nil, "preserve Mason's wrapper contract")
    for _, ft in ipairs(config.filetypes) do
        assert(not seen[ft], "duplicate/overlapping filetype: " .. ft)
        seen[ft] = config
    end
end

assert(
    vim.deep_equal(vim.json.decode(vim.json.encode(harper.settings)), {
        ["harper-ls"] = {
            linters = { SpellCheck = true },
            diagnosticSeverity = "hint",
            dialect = "American",
            codeActions = { ForceStable = true },
        },
    }),
    "exact serializable Harper settings without custom dictionary paths"
)
assert(vim.deep_equal(vim.json.decode(vim.json.encode(typos.init_options)), { diagnosticSeverity = "Hint" }))
assert(vim.deep_equal(typos.cmd_env, { RUST_LOG = "typos_lsp=error" }))
for _, ft in ipairs(harper.filetypes) do
    local expected = ({ text = "plaintext", plaintex = "tex" })[ft] or ft
    assert(harper.get_language_id(123, ft) == expected, "Harper language ID: " .. ft)
end
for _, ft in ipairs({ "markdown", "text", "tex", "plaintex", "typst", "quarto", "gitcommit", "asciidoc", "html" }) do
    assert(seen[ft] == harper, "missing prose scope: " .. ft)
end
for _, ft in ipairs({
    "python",
    "lua",
    "rust",
    "java",
    "c",
    "cpp",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "sh",
    "bash",
    "zsh",
    "go",
    "ruby",
    "cs",
    "php",
    "kotlin",
    "css",
    "bib",
    "json",
    "jsonc",
    "yaml",
    "toml",
}) do
    assert(seen[ft] == typos, "missing code/config scope: " .. ft)
end
for _, ft in ipairs({ "", "ipynb", "help", "TelescopePrompt", "terminal", "unknown", "binary" }) do
    assert(not seen[ft], "unexpected scope: " .. ft)
end

local buffer = vim.api.nvim_create_buf(true, false)
local name = vim.fn.tempname() .. ".py"
vim.api.nvim_buf_set_name(buffer, name)
vim.bo[buffer].filetype = "python"
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "# A comment" })
assert(#vim.fn.win_findbuf(buffer) == 0 and spelling.eligible(buffer), "hidden loaded source must be eligible")

local global_config = vim.deepcopy(vim.diagnostic.config())
local compiler_namespaces = {
    vim.lsp.diagnostic.get_namespace(9000, false),
    vim.lsp.diagnostic.get_namespace(9000, true),
}
local compiler_configs = {}
for _, ns in ipairs(compiler_namespaces) do
    compiler_configs[ns] = vim.deepcopy(vim.diagnostic.config(nil, ns))
end
local original_config = vim.diagnostic.config
local namespace_calls = {}
vim.diagnostic.config = function(opts, ns)
    if opts then
        assert(ns ~= nil, "never configure global diagnostics")
        namespace_calls[#namespace_calls + 1] = { ns = ns, opts = vim.deepcopy(opts) }
    end
    return original_config(opts, ns)
end
local original_attach = spelling.on_attach
local attach_calls = 0
spelling.on_attach = function(client, bufnr)
    assert(bufnr == buffer, "delegate the target buffer")
    attach_calls = attach_calls + 1
    original_attach(client, bufnr)
end
for index, config in ipairs({ harper, typos }) do
    local client = { id = 9000 + index, request = no_process, notify = no_process }
    config.on_attach(client, buffer)
    for offset, is_pull in ipairs({ false, true }) do
        local ns = vim.lsp.diagnostic.get_namespace(client.id, is_pull)
        local call = namespace_calls[(index - 1) * 2 + offset]
        assert(call.ns == ns and vim.deep_equal(call.opts, {
            signs = false,
            virtual_text = false,
            update_in_insert = false,
        }), "only own push/pull namespace and bounded diagnostic options")
        local opts = vim.diagnostic.config(nil, ns)
        assert(opts.signs == false and opts.virtual_text == false and opts.update_in_insert == false)
        assert(opts.underline == nil and opts.float == nil and opts.severity_sort == nil, "inherit global rendering")
    end
end
assert(attach_calls == 2 and #namespace_calls == 4, "both servers delegate exactly two namespace updates")
assert(vim.deep_equal(vim.diagnostic.config(), global_config), "global diagnostics unchanged")
for _, ns in ipairs(compiler_namespaces) do
    assert(vim.deep_equal(vim.diagnostic.config(nil, ns), compiler_configs[ns]), "compiler diagnostics unchanged")
end
spelling.on_attach = original_attach
vim.diagnostic.config = original_config

for _, allowed in ipairs({ vim.fs.dirname(name) .. "/notes:2026.txt", "C:\\fixture\\source.py", "C:/fixture/source.py" }) do
    vim.api.nvim_buf_set_name(buffer, allowed)
    assert(spelling.eligible(buffer), "colon filenames and drive paths remain eligible: " .. allowed)
end
vim.api.nvim_buf_set_name(buffer, name)

for _, config in ipairs({ harper, typos }) do
    local result
    config.root_dir(buffer, function(dir)
        result = dir
    end)
    assert(result == vim.fs.dirname(name), "standalone source gets a parent workspace")
    vim.api.nvim_buf_set_name(buffer, vim.fn.getcwd() .. "/spelling-fixture.py")
    config.root_dir(buffer, function(dir)
        result = dir
    end)
    assert(result == vim.fn.getcwd(), "native marker search finds repository root")
    vim.api.nvim_buf_set_name(buffer, name)
end

local root, root_buf, root_markers
local original_root = vim.fs.root
vim.fs.root = function(bufnr, markers)
    root_buf, root_markers = bufnr, markers
    return root
end
local function check_root(config, expected)
    local calls, result = 0, nil
    config.root_dir(buffer, function(dir)
        calls, result = calls + 1, dir
    end)
    assert(calls == (expected and 1 or 0) and result == expected, "root callback eligibility/fallback")
    if expected then
        assert(root_buf == buffer and root_markers == config.root_markers, "use target buffer and server markers")
    end
end
for _, config in ipairs({ harper, typos }) do
    root = nil
    check_root(config, vim.fs.dirname(name))
    root = "/fixture/project"
    check_root(config, root)
end

for _, kind in ipairs({ "nofile", "prompt", "acwrite", "quickfix" }) do
    vim.bo[buffer].buftype = kind
    assert(not spelling.eligible(buffer), "utility buffer: " .. kind)
    check_root(typos, nil)
end
vim.bo[buffer].buftype = ""
local terminal = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(terminal, vim.fn.tempname() .. ".py")
vim.api.nvim_open_term(terminal, {})
assert(not spelling.eligible(terminal), "terminal buffer")
vim.api.nvim_buf_delete(terminal, { force = true })
for _, excluded in ipairs({
    "",
    "oil:///fixture",
    "jdt://fixture",
    "untitled:fixture",
    name .. ".ipynb",
    name .. ".IPYNB",
}) do
    vim.api.nvim_buf_set_name(buffer, excluded)
    for _, ft in ipairs({ "python", "json" }) do
        vim.bo[buffer].filetype = ft
        assert(not spelling.eligible(buffer), "excluded name: " .. excluded)
        check_root(harper, nil)
        check_root(typos, nil)
    end
end
vim.api.nvim_buf_set_name(buffer, name)
local original_realpath = vim.uv.fs_realpath
vim.uv.fs_realpath = function(path)
    assert(path == name)
    return "/fixture/notebook.ipynb"
end
assert(not spelling.eligible(buffer), "resolved notebook alias must be excluded")
check_root(typos, nil)
vim.uv.fs_realpath = original_realpath

vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { string.rep("x", 1024 * 1024 + 1) })
assert(not spelling.eligible(buffer), "oversize source")
check_root(typos, nil)
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "# A comment" })
local float = vim.api.nvim_open_win(buffer, false, { relative = "editor", row = 0, col = 0, width = 20, height = 1 })
assert(spelling.eligible(buffer), "normal source eligibility must not depend on window type")
vim.api.nvim_win_close(float, true)
vim.api.nvim_buf_delete(buffer, { unload = true, force = true })
assert(not spelling.eligible(buffer), "unloaded source")
check_root(typos, nil)
vim.api.nvim_buf_delete(buffer, { force = true })
assert(not spelling.eligible(buffer), "invalid source")
vim.fs.root = original_root
assert(process_calls == 0, "no process or request calls")
print(
    "PASS: spelling scopes, server settings/language IDs, isolated diagnostics, eligibility/roots; 0 process/request calls"
)
