-- Run from the config root: lua tests/notebook_config.lua
-- Stub Neovim and plugins: no provider, kernel, installs, or startup side effects.
package.path = "./lua/?.lua;" .. package.path

local options, autocmd, user_command
local mappings, notifications, executed = {}, {}, {}
local executable, command_exists = true, true
vim = {
    env = {},
    g = {},
    b = { [1] = {} },
    bo = { [1] = { buftype = "" } },
    log = { levels = { WARN = 2 } },
    notify = function(message)
        table.insert(notifications, message)
    end,
    fn = {
        stdpath = function(kind)
            assert(kind == "data")
            return "/test/data/nvim"
        end,
        fnamemodify = function(path, modifier)
            assert(modifier == ":h")
            return path:match("^(.*)/[^/]+$")
        end,
        executable = function()
            return executable and 1 or 0
        end,
        exists = function()
            return command_exists and 2 or 0
        end,
    },
    api = {
        nvim_get_current_buf = function()
            return 1
        end,
        nvim_create_augroup = function(name, opts)
            assert(name == "UserNotebook" and opts.clear)
            return 1
        end,
        nvim_create_autocmd = function(events, opts)
            if events == "FileType" then
                assert(opts.pattern == "molten_output" and opts.group == 1)
                return
            end
            assert(opts.pattern == "*.ipynb" and opts.group == 1)
            assert(table.concat(events, ",") == "BufReadPost,BufNewFile,BufFilePost")
            autocmd = opts.callback
        end,
        nvim_create_user_command = function(name, callback)
            assert(name == "NotebookEnable")
            user_command = callback
        end,
        nvim_get_current_win = function()
            return 1
        end,
        nvim_list_wins = function()
            return {}
        end,
    },
    keymap = {
        set = function(mode, key, callback, opts)
            assert(opts.buffer == 1)
            mappings[mode .. key] = callback
        end,
    },
    cmd = function(command)
        table.insert(executed, command)
    end,
}
package.preload.jupytext = function()
    return {
        setup = function(opts)
            options = opts
        end,
    }
end

local notebook = require("user.notebook")
assert(vim.g.python3_host_prog == "/test/data/nvim/python-provider/bin/python")
assert(options.jupytext == "/test/data/nvim/python-provider/bin/jupytext")
assert(options.format == "py:percent" and options.update and options.autosync)
assert(options.async_write == false)
assert(vim.g.molten_image_provider == "none")
assert(vim.g.molten_auto_init_behavior == "raise")
assert(not vim.g.molten_auto_image_popup and not vim.g.molten_auto_open_html_in_browser)
assert(not vim.g.molten_auto_open_output and vim.g.molten_virt_text_output)
assert(next(mappings) == nil and #executed == 0)
autocmd({ buf = 1 })
for _, key in ipairs({ "mi", "me", "ml", "mc", "mo", "mq", "md", "mx" }) do
    assert(type(mappings["n<Space>" .. key]) == "function")
end
assert(mappings["x<Space>mv"]:find(":<C%-u>"))
assert(#executed == 0)
mappings["n<Space>mi"]()
assert(executed[1] == "MoltenInit")
mappings["n<Space>mo"]()
assert(executed[2] == "noautocmd MoltenEnterOutput")
mappings["n<Space>mq"]()
assert(executed[3] == "MoltenHideOutput")
user_command()
command_exists = false
notebook.run("MoltenEvaluateLine")
assert(#executed == 3 and notifications[#notifications]:find("UpdateRemotePlugins"))
executable = false
notebook.run("MoltenInit")
assert(#executed == 3 and notifications[#notifications]:find("Missing Python provider"))
package.loaded["user.notebook"] = nil
options = nil
require("user.notebook")
assert(options == nil and notifications[#notifications]:find("remain raw JSON"))
package.loaded["user.python"] = nil
vim.env.NVIM_PYTHON_HOST = "/custom/provider/bin/python"
local python = require("user.python")
assert(python.host == vim.env.NVIM_PYTHON_HOST)
assert(python.jupytext == "/custom/provider/bin/jupytext")
assert(vim.g.python3_host_prog == python.host)
print("PASS: notebook setup, scoped mappings, explicit initialization, dependency guards, provider override")
