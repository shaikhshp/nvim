local dap_ok, dap = pcall(require, "dap")
if not dap_ok then
    return
end

local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end
map("<leader>dd", dap.continue, "Debug continue")
map("<leader>dc", dap.clear_breakpoints, "Debug clear breakpoints")
map("<leader>db", dap.toggle_breakpoint, "Debug toggle breakpoint")
map("<leader>dx", dap.disconnect, "Debug disconnect")
map("<leader>dt", dap.terminate, "Debug terminate")
map("<leader>di", dap.step_into, "Debug step into")
map("<leader>do", dap.step_out, "Debug step out")
map("<leader>dp", dap.step_over, "Debug step over")
map("<leader>dB", function()
    vim.ui.input({ prompt = "Breakpoint condition: " }, function(condition)
        if condition then
            dap.set_breakpoint(condition)
        end
    end)
end, "Debug conditional breakpoint")
map("<leader>dl", dap.run_last, "Debug run last")
map("<leader>dr", dap.restart, "Debug restart")
map("<leader>de", dap.repl.toggle, "Debug toggle REPL")

local ui_ok, dapui = pcall(require, "dapui")
if not ui_ok then
    return
end
map("<leader>du", dapui.toggle, "Debug toggle UI")

dapui.setup({
    icons = {
        expanded = "▾",
        collapsed = "▸",
        current_frame = "▸",
    },

    controls = {
        enabled = true,
        element = "repl", -- which element to attach the controls to
        icons = {
            pause = "",
            play = "",
            step_into = "",
            step_over = "",
            step_out = "",
            step_back = "",
            run_last = "↻",
            terminate = "□",
        },
    },

    mappings = {
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        edit = "e",
        repl = "r",
        toggle = "t",
    },

    expand_lines = true,

    layouts = {
        {
            elements = {
                { id = "scopes", size = 0.33 },
                { id = "breakpoints", size = 0.17 },
                { id = "stacks", size = 0.25 },
                { id = "watches", size = 0.25 },
            },
            size = 40,
            position = "left",
        },
        {
            elements = { "repl", "console" },
            size = 10,
            position = "bottom",
        },
    },

    floating = {
        max_height = 0.9,
        max_width = 0.5,
        border = "single",
        mappings = {
            close = { "q", "<Esc>" },
        },
    },

    windows = { indent = 1 },
})

dap.listeners.before.attach.dapui_config = function()
    dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
    dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
end
