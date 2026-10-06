local M = {}

function M.build(plugin)
    require("lazy").load({ plugins = { plugin.name } })
    local cwd = vim.fn.getcwd()
    local cd = vim.fn.haslocaldir() == 1 and "lcd " or vim.fn.haslocaldir(-1, 0) == 1 and "tcd " or "cd "
    local ok, err = pcall(vim.fn["mkdp#util#install_sync"])
    -- The upstream synchronous installer changes the window-local directory.
    vim.cmd(cd .. vim.fn.fnameescape(cwd))
    assert(ok, err)
    local platform = vim.fn["mkdp#util#get_platform"]()
    local binary = plugin.dir .. "/app/bin/markdown-preview-" .. platform .. (platform == "win" and ".exe" or "")
    assert(vim.fn.executable(binary) == 1, "Markdown preview backend missing; inspect installer output")
end

return M
