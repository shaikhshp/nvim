-- Run: nvim --headless -u NONE -i NONE -l tests/formatting_config.lua
vim.opt.runtimepath:append(vim.fn.getcwd())
local calls, notices, setup = {}, {}, nil
local fail = false
package.preload.conform = function()
    return {
        setup = function(opts)
            setup = opts
        end,
        format = function(opts)
            if fail then
                error("fixture formatter failure")
            end
            calls[#calls + 1] = opts
            return true
        end,
    }
end
vim.notify = function(message)
    notices[#notices + 1] = message
end
local clients = { { id = 1, name = "other" }, { id = 2, name = "ruff" }, { id = 3, name = "ruff" } }
local get_clients = vim.lsp.get_clients
vim.lsp.get_clients = function()
    return vim.deepcopy(clients)
end
local formatting = require("user.formatting")
local buffer = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_name(buffer, vim.fn.tempname() .. ".py")
vim.bo[buffer].filetype = "python"
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "x=1" })
assert(setup.formatters_by_ft.python[1] == "ruff_format")
assert(setup.formatters_by_ft.python[2] == "black" and setup.formatters_by_ft.python.stop_after_first)
assert(formatting.format(buffer))
local options = calls[1]
assert(options.timeout_ms == 2000 and options.async == false and options.lsp_format == "fallback")
assert(not options.filter(clients[1]) and options.filter(clients[2]) and not options.filter(clients[3]))

local function save()
    vim.api.nvim_exec_autocmds("BufWritePre", { buffer = buffer })
end
save()
assert(#calls == 2)
formatting.toggle()
save()
assert(#calls == 2 and vim.b.disable_autoformat)
formatting.toggle(true)
formatting.toggle()
save()
assert(#calls == 2 and vim.g.disable_autoformat and not vim.b.disable_autoformat)
assert(formatting.format(buffer) and #calls == 3)
formatting.toggle(true)
save()
assert(#calls == 4)

for _, option in ipairs({ "readonly", "modifiable" }) do
    local old = vim.bo[buffer][option]
    vim.bo[buffer][option] = option == "readonly"
    assert(not formatting.eligible(buffer))
    save()
    assert(#calls == 4)
    vim.bo[buffer][option] = old
end
vim.bo[buffer].buftype = "nofile"
assert(not formatting.format(buffer))
vim.bo[buffer].buftype = ""
vim.api.nvim_buf_set_name(buffer, vim.fn.tempname() .. ".ipynb")
assert(not formatting.format(buffer))
vim.api.nvim_buf_set_name(buffer, vim.fn.tempname() .. ".py")
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { string.rep("x", 1024 * 1024 + 1) })
assert(not formatting.format(buffer))
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "x=1" })
fail = true
save()
assert(notices[#notices]:find("fixture formatter failure", 1, true))
vim.lsp.get_clients = get_clients
print("PASS: formatter ordering, one LSP fallback, toggles, exclusions, and save-error guard")
