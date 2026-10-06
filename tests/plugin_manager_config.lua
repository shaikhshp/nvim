-- Run: nvim --headless -u NONE -i NONE -l tests/plugin_manager_config.lua
local real_vim = vim
local specs, options, systems, loads, commands, notices
local present, fail_at, scope, install_error, backend = true, nil, 0, false, true
local cwd = "/fixture/project"
local fake = {
    uv = {
        fs_stat = function()
            return present and {} or nil
        end,
    },
    v = { shell_error = 0 },
    log = { levels = { ERROR = 1 } },
    opt = {
        runtimepath = {
            prepend = function(path)
                commands[#commands + 1] = { prepend = path }
            end,
        },
    },
    fn = {
        stdpath = function()
            return "/fixture/data"
        end,
        getcwd = function()
            return cwd
        end,
        haslocaldir = function(window)
            return (window == -1 and scope == 2 or window ~= -1 and scope == 1) and 1 or 0
        end,
        fnameescape = function(path)
            return path
        end,
        executable = function(path)
            assert(path == "/fixture/markdown-preview.nvim/app/bin/markdown-preview-linux")
            return backend and 1 or 0
        end,
        ["mkdp#util#get_platform"] = function()
            return "linux"
        end,
        ["mkdp#util#install_sync"] = function()
            assert(loads[#loads].plugins[1] == "markdown-preview.nvim", "Build must explicitly load the plugin first")
            cwd = "/fixture/app"
            if install_error then
                error("fixture installer failure")
            end
        end,
    },
}
fake.fn.system = function(command)
    systems[#systems + 1] = command
    fake.v.shell_error = #systems == fail_at and 1 or 0
    return ""
end
fake.notify = function(message)
    notices[#notices + 1] = message
end
fake.cmd = function(command)
    commands[#commands + 1] = command
    cwd = command:match("^%w+ (.+)$")
end
local original_lazy = package.loaded.lazy
local original_markdown = package.loaded["user.markdown-preview"]
package.loaded["user.markdown-preview"] = dofile("lua/user/markdown-preview.lua")
package.loaded.lazy = {
    setup = function(plugin_specs, opts)
        specs, options = plugin_specs, opts
    end,
    load = function(opts)
        loads[#loads + 1] = opts
    end,
}
local function source()
    specs, options = nil, nil
    systems, loads, commands, notices = {}, {}, {}, {}
    fake.v.shell_error = 0
    _G.vim = fake
    local ok, err = pcall(dofile, "lua/user/plugins.lua")
    _G.vim = real_vim
    assert(ok, err)
end
source()
assert(#systems == 0 and #specs == 57, "Installed manager must not provision anything")
assert(options.defaults.lazy == false and options.defaults.version == false)
assert(options.install.missing == false and options.checker.enabled == false)
assert(options.local_spec == false and options.pkg.enabled == false and options.rocks.enabled == false)
assert(options.performance.rtp.disabled_plugins[1] == "packer_compiled")
local plugins = {}
for _, spec in ipairs(specs) do
    local name = spec.name or spec[1]:match("/([^/]+)$")
    assert(not plugins[name], "Duplicate declaration: " .. name)
    plugins[name] = spec
    assert(spec.run == nil and spec.requires == nil and spec.as == nil and spec.opt == nil)
    if name ~= "codecompanion.nvim" and name ~= "minuet-ai.nvim" then
        assert(spec.lazy ~= true and spec.event == nil and spec.ft == nil and spec.cmd == nil)
    end
end
assert(plugins["lazy.nvim"].commit == "85c7ff3711b730b4030d03144f6db6375044ae82")
assert(plugins["lazy.nvim"].pin == true and not plugins["packer.nvim"])
assert(plugins.catppuccin[1] == "catppuccin/nvim" and plugins["rose-pine"][1] == "rose-pine/neovim")
assert(plugins["codecompanion.nvim"].tag == "v19.27.0")
assert(plugins["minuet-ai.nvim"].commit == "3b0a4c5f97b7124d94302c608fbe01c0270d4fbe")
assert(plugins["plenary.nvim"].commit == "74b06c6c75e4eeb3108ec01852001636d85a932b")
for _, name in ipairs({ "codecompanion.nvim", "minuet-ai.nvim" }) do
    local spec = plugins[name]
    assert(spec.lazy == true and spec.module == false)
    assert(
        spec.event == nil
            and spec.ft == nil
            and spec.cmd == nil
            and spec.keys == nil
            and spec.config == nil
            and spec.opts == nil
    )
end
assert(plugins["nvim-nio"].lazy == false)
assert(plugins["nvim-treesitter"].build == ":TSUpdate")
assert(plugins["molten-nvim"].build == ":UpdateRemotePlugins")
local lock = real_vim.json.decode(table.concat(real_vim.fn.readfile("lazy-lock.json"), "\n"))
for name, spec in pairs(plugins) do
    assert(lock[name] and #lock[name].commit == 40, "Missing locked revision: " .. name)
    if spec.commit then
        assert(lock[name].commit == spec.commit, "Lock does not preserve explicit pin: " .. name)
    end
end
for name in pairs(lock) do
    assert(plugins[name], "Undeclared lockfile entry: " .. name)
end

local markdown = plugins["markdown-preview.nvim"]
for _, mode in ipairs({ 0, 1, 2 }) do
    scope, cwd = mode, "/fixture/project"
    _G.vim = fake
    local ok, err = pcall(markdown.build, { name = "markdown-preview.nvim", dir = "/fixture/markdown-preview.nvim" })
    _G.vim = real_vim
    assert(ok, err)
    assert(cwd == "/fixture/project")
    assert(commands[#commands] == ({ [0] = "cd", [1] = "lcd", [2] = "tcd" })[mode] .. " /fixture/project")
end
install_error = true
_G.vim = fake
local ok, err = pcall(markdown.build, { name = "markdown-preview.nvim", dir = "/fixture/markdown-preview.nvim" })
_G.vim = real_vim
assert(not ok and tostring(err):find("fixture installer failure", 1, true) and cwd == "/fixture/project")
install_error, backend = false, false
_G.vim = fake
ok, err = pcall(markdown.build, { name = "markdown-preview.nvim", dir = "/fixture/markdown-preview.nvim" })
_G.vim = real_vim
assert(not ok and tostring(err):find("backend missing", 1, true))

present = false
source()
assert(#systems == 2 and systems[1][2] == "clone" and systems[2][4] == "checkout")
assert(systems[2][5] == "85c7ff3711b730b4030d03144f6db6375044ae82")
for _, failure in ipairs({ 1, 2 }) do
    fail_at = failure
    source()
    assert(specs == nil and #notices == 1 and #commands == 0 and #systems == failure)
end
local installed
package.loaded.lazy.install = function(opts)
    installed = opts
end
dofile("lua/user/keymaps.lua")
local install_map = real_vim.fn.maparg(" pi", "n", false, true)
assert(install_map.rhs == "<cmd>lua require('lazy').install({ lockfile = true })<CR>")
real_vim.api.nvim_feedkeys(" pi", "xt", false)
assert(installed.lockfile == true, "Install mapping must request locked checkout")
package.loaded.lazy = original_lazy
package.loaded["user.markdown-preview"] = original_markdown
print(
    "PASS: bootstrap guards, pins, eager/AI policy, build hooks, and disabled automatic provisioning; no real processes/network"
)
