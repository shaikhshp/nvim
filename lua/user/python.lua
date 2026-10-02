local M = {}

M.directory = vim.fn.stdpath("data") .. "/python-provider"
M.host = vim.env.NVIM_PYTHON_HOST
if not M.host or M.host == "" then
    M.host = M.directory .. "/bin/python"
end
M.jupytext = vim.fn.fnamemodify(M.host, ":h") .. "/jupytext"

-- Load this module before plugins and before :UpdateRemotePlugins so discovery
-- cannot silently select a project virtualenv or the system Python instead.
vim.g.python3_host_prog = M.host

function M.project_python(root)
    if not root then
        local clients = vim.lsp.get_clients({ bufnr = 0, name = "pyright" })
        root = clients[1] and clients[1].config.root_dir
    end
    root = root
        or vim.fs.root(
            0,
            { "pyrightconfig.json", "Pipfile", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" }
        )
        or vim.fn.getcwd()
    local suffix = vim.fn.has("win32") == 1 and "/Scripts/python.exe" or "/bin/python"
    local candidates = { root .. "/.venv" .. suffix, root .. "/venv" .. suffix, vim.fn.expand("~/anaconda3") .. suffix }
    local env = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
    if env then
        table.insert(candidates, 1, env .. suffix)
    end
    for _, candidate in ipairs(candidates) do
        if vim.fn.executable(candidate) == 1 then
            return candidate
        end
    end
    local command = vim.fn.exepath("python3")
    return command ~= "" and command or vim.fn.exepath("python")
end

return M
