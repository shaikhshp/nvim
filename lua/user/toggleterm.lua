local M = {}
local status_ok, toggleterm = pcall(require, "toggleterm")
if not status_ok then
    return M
end

local terminal_ok, terminal = pcall(require, "toggleterm.terminal")
if not terminal_ok then
    return M
end

toggleterm.setup({
    size = 20,
    open_mapping = [[<c-\>]],
    hide_numbers = true,
    shade_filetypes = {},
    shade_terminals = true,
    shading_factor = 2,
    start_in_insert = true,
    insert_mappings = true,
    persist_size = true,
    direction = "float",
    close_on_exit = true,
    shell = vim.o.shell,
    float_opts = {
        border = "curved",
        winblend = 0,
        highlights = { border = "Normal", background = "Normal" },
    },
})

vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("UserToggleterm", { clear = true }),
    pattern = "term://*#toggleterm#*",
    callback = function(args)
        local opts = { buffer = args.buf, silent = true }
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
        for _, direction in ipairs({ "h", "j", "k", "l" }) do
            vim.keymap.set("t", "<C-" .. direction .. ">", [[<C-\><C-n><C-W>]] .. direction, opts)
        end
    end,
})

local lazygit = terminal.Terminal:new({ cmd = "lazygit", hidden = true })
local node = terminal.Terminal:new({ cmd = "node", hidden = true })
local ncdu = terminal.Terminal:new({ cmd = "ncdu", hidden = true })
local htop = terminal.Terminal:new({ cmd = "htop", hidden = true })
local python = terminal.Terminal:new({ cmd = "python", hidden = true })

function M.lazygit_toggle()
    lazygit:toggle()
end

function M.node_toggle()
    node:toggle()
end

function M.ncdu_toggle()
    ncdu:toggle()
end

function M.htop_toggle()
    htop:toggle()
end

function M.python_toggle()
    python:toggle()
end

return M
