require("dapui").setup({
    -- 1) Icons for expand/collapse in side panels
    icons = {
        expanded = "▾",      -- or e.g. "v", "⯆", ""
        collapsed = "▸",     -- or e.g. ">", "⯈", ""
        current_frame = "▸", -- shown for the current scope/frame
    },

    -- 2) Icons for debugging controls (play, pause, step, etc.)
    controls = {
        enabled = true,
        element = "repl",  -- which element to attach the controls to
        icons = {
            pause = "",      -- or e.g. "", ""
            play = "",       -- or e.g. "", "契"
            step_into = "",  -- or e.g. ""
            step_over = "",  -- or e.g. ""
            step_out = "",   -- or e.g. ""
            step_back = "",  -- or e.g. ""
            run_last = "↻",   -- or e.g. ""
            terminate = "□",  -- or e.g. "", ""
        },
    },

    -- Other configs (unchanged), included here for completeness:
    mappings = {
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        edit = "e",
        repl = "r",
        toggle = "t",
    },

    -- Whether to expand all lines in your frames/scopes pane
    expand_lines = true,

    -- Layout configuration
    layouts = {
        {
            elements = {
                { id = "scopes", size = 0.33 },
                { id = "breakpoints", size = 0.17 },
                { id = "stacks", size = 0.25 },
                { id = "watches", size = 0.25 },
            },
            size = 40,      -- height of the window
            position = "left",
        },
        {
            elements = { "repl", "console" },
            size = 10,
            position = "bottom",
        },
    },

    -- Floating window config
    floating = {
        max_height = 0.9,
        max_width = 0.5,
        border = "single",
        mappings = {
            close = { "q", "<Esc>" },
        },
    },

    windows = { indent = 1 },
    render = {
        max_type_length = nil, -- Can be integer to truncate variable types
    },
})

local dap, dapui = require("dap"), require("dapui")
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

vim.api.nvim_set_keymap('n', '<leader>dd', '<cmd>DapContinue<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>dc', '<cmd>DapClearBreakpoints<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>db', '<cmd>DapToggleBreakpoint<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>dx', '<cmd>DapDisconnect<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>dt', '<cmd>DapTerminate<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>di', '<cmd>DapStepInto<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>do', '<cmd>DapStepOut<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>dp', '<cmd>DapStepOver<CR>', { noremap = true, silent = true })

