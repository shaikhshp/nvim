-- Run: nvim --headless -u NONE -i NONE -l tests/persistence_config.lua
vim.opt.runtimepath:append(vim.fn.getcwd())
local original = vim.o.sessionoptions
package.preload.persistence = function()
    error("fixture plugin unavailable")
end
dofile("lua/user/persistence.lua")
assert(vim.o.sessionoptions == original, "Missing plugin must not change session options")

local setup, restored
package.loaded.persistence = nil
package.preload.persistence = function()
    return {
        setup = function(opts)
            setup = opts
        end,
        load = function(opts)
            restored = opts or {}
        end,
    }
end
dofile("lua/user/persistence.lua")
assert(setup.need == 1 and setup.branch == true)
assert(restored == nil, "Setup must not restore automatically")
assert(vim.deep_equal(vim.opt.sessionoptions:get(), { "buffers", "curdir", "folds", "tabpages", "winsize" }))

local dashboard = {
    section = { header = {}, buttons = {}, footer = { opts = {} } },
    opts = { opts = {} },
    button = function(key, label, action)
        return { key = key, label = label, action = action }
    end,
}
dashboard.section.header.opts = {}
dashboard.section.buttons.opts = {}
local alpha_setup
package.preload.alpha = function()
    return {
        setup = function(opts)
            alpha_setup = opts
        end,
    }
end
package.preload["alpha.themes.dashboard"] = function()
    return dashboard
end
dofile("lua/user/alpha.lua")
assert(alpha_setup == dashboard.opts)
local buttons = {}
for _, button in ipairs(dashboard.section.buttons.val) do
    assert(not buttons[button.key], "Conflicting dashboard key: " .. button.key)
    buttons[button.key] = button
end
assert(buttons.f and buttons.e and buttons.p and buttons.r and buttons.t and buttons.c and buttons.q)
assert(buttons.s.action == "<cmd>lua require('persistence').load()<CR>")
assert(buttons.l.action == "<cmd>lua require('persistence').load({ last = true })<CR>")
vim.cmd("lua require('persistence').load()")
assert(vim.deep_equal(restored, {}))
vim.cmd("lua require('persistence').load({ last = true })")
assert(restored.last == true)
assert(vim.fn.maparg("s", "n") == "" and vim.fn.maparg("l", "n") == "", "No global session keys")
print("PASS: plugin guard, session scope, explicit restore, and unique dashboard actions")
