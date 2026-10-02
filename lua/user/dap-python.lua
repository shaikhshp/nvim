local ok, dap_python = pcall(require, "dap-python")
local dap_ok, dap = pcall(require, "dap")
if not ok or not dap_ok then
    return
end

local windows = vim.fn.has("win32") == 1
local python = vim.fn.stdpath("data")
    .. "/mason/packages/debugpy/venv/"
    .. (windows and "Scripts/python.exe" or "bin/python")
dap_python.setup(python)
local adapter = dap.adapters.python
dap.adapters.python = function(callback, config)
    if config.request ~= "attach" and vim.fn.executable(python) ~= 1 then
        vim.notify("Install Mason debugpy before debugging Python", vim.log.levels.WARN)
        return
    end
    adapter(callback, config)
end
dap.adapters.debugpy = dap.adapters.python
dap_python.resolve_python = function()
    return require("user.python").project_python()
end
