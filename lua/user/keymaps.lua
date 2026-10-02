vim.g.mapleader = " "
vim.g.maplocalleader = " "
local function map(mode, key, action, desc)
    vim.keymap.set(mode, key, action, { silent = true, desc = desc })
end
map({ "n", "x", "o" }, "<Space>", "<Nop>", "Leader")

for _, direction in ipairs({ { "h", "left" }, { "j", "down" }, { "k", "up" }, { "l", "right" } }) do
    map("n", "<C-" .. direction[1] .. ">", "<C-w>" .. direction[1], "Focus " .. direction[2] .. " window")
end
map("n", "<C-d>", "<C-d>zz", "Half-page down and center")
map("n", "<C-u>", "<C-u>zz", "Half-page up and center")
map("n", "n", "nzzzv", "Next search match")
map("n", "N", "Nzzzv", "Previous search match")
map("n", "<C-Up>", "<cmd>resize -2<CR>", "Decrease height")
map("n", "<C-Down>", "<cmd>resize +2<CR>", "Increase height")
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", "Decrease width")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", "Increase width")
map("n", "L", "<cmd>bnext<CR>", "Next buffer")
map("n", "H", "<cmd>bprevious<CR>", "Previous buffer")
map("n", "<A-j>", "<cmd>move .+1<CR>==", "Move line down")
map("n", "<A-k>", "<cmd>move .-2<CR>==", "Move line up")
for _, direction in ipairs({ { "h", "Left" }, { "j", "Down" }, { "k", "Up" }, { "l", "Right" } }) do
    map("i", "<C-" .. direction[1] .. ">", "<" .. direction[2] .. ">", "Move " .. direction[2]:lower())
end
map("i", "jk", "<Esc>", "Leave Insert mode")
map("i", "kj", "<Esc>", "Leave Insert mode")
map("x", "<", "<gv^", "Indent left")
map("x", ">", ">gv^", "Indent right")
map("x", "p", "\"_dP", "Paste without replacing register")
map("x", "J", ":move '>+1<CR>gv=gv", "Move selection down")
map("x", "K", ":move '<-2<CR>gv=gv", "Move selection up")
map("x", "<A-j>", ":move '>+1<CR>gv=gv", "Move selection down")
map("x", "<A-k>", ":move '<-2<CR>gv=gv", "Move selection up")

local commands = {
    a = { "Alpha", "Dashboard" },
    b = { "Telescope buffers", "Buffers" },
    T = { "Telescope", "Telescope" },
    e = { "NvimTreeToggle", "Explorer" },
    w = { "write", "Save" },
    q = { "quit", "Quit window" },
    c = { "Bdelete", "Close buffer" },
    h = { "nohlsearch", "Clear search highlighting" },
    f = { "Telescope find_files", "Find files" },
    F = { "Telescope current_buffer_fuzzy_find", "Search current buffer" },
    P = { "Telescope projects", "Projects" },
    ["|"] = { "Glow", "Markdown terminal preview" },
    r = { "source $MYVIMRC", "Source entrypoint (cached modules are not reloaded)" },
    pc = { "PackerCompile", "Compile plugin loader" },
    pi = { "PackerInstall", "Install plugins" },
    ps = { "PackerSync", "Sync plugins" },
    pS = { "PackerStatus", "Plugin status" },
    pu = { "PackerUpdate", "Update plugins" },
    go = { "Telescope git_status", "Changed files" },
    gb = { "Telescope git_branches", "Git branches" },
    gc = { "Telescope git_commits", "Git commits" },
    gd = { "Gitsigns diffthis HEAD", "Diff against HEAD" },
    ld = { "Telescope diagnostics bufnr=0", "Buffer diagnostics" },
    lw = { "Telescope diagnostics", "Workspace diagnostics" },
    li = { "LspInfo", "LSP information" },
    lm = { "Mason", "Mason tools" },
    ls = { "Telescope lsp_document_symbols", "Document symbols" },
    lS = { "Telescope lsp_dynamic_workspace_symbols", "Workspace symbols" },
    sb = { "Telescope git_branches", "Git branches" },
    sc = { "Telescope colorscheme", "Colorschemes" },
    sh = { "Telescope help_tags", "Help" },
    sM = { "Telescope man_pages", "Manual pages" },
    sr = { "Telescope oldfiles", "Recent files" },
    sR = { "Telescope registers", "Registers" },
    sk = { "Telescope keymaps", "Keymaps" },
    sC = { "Telescope commands", "Commands" },
    sg = { "Telescope live_grep", "Search project text" },
    tf = { "ToggleTerm direction=float", "Floating terminal" },
    th = { "ToggleTerm size=10 direction=horizontal", "Horizontal terminal" },
    tv = { "ToggleTerm size=80 direction=vertical", "Vertical terminal" },
}
for key, entry in pairs(commands) do
    map("n", "<leader>" .. key, "<cmd>" .. entry[1] .. "<CR>", entry[2])
end
for key, entry in pairs({
    gj = { "next_hunk", "Next hunk" },
    gk = { "prev_hunk", "Previous hunk" },
    gl = { "blame_line", "Blame line" },
    gp = { "preview_hunk", "Preview hunk" },
    gr = { "reset_hunk", "Reset hunk" },
    gR = { "reset_buffer", "Reset buffer" },
    gs = { "stage_hunk", "Stage hunk" },
    gu = { "undo_stage_hunk", "Undo staged hunk" },
}) do
    map("n", "<leader>" .. key, function()
        require("gitsigns")[entry[1]]()
    end, entry[2])
end
for key, entry in pairs({
    gg = { "lazygit_toggle", "Lazygit" },
    tn = { "node_toggle", "Node terminal" },
    tu = { "ncdu_toggle", "Disk usage" },
    tt = { "htop_toggle", "Process monitor" },
    tp = { "python_toggle", "Python terminal" },
}) do
    map("n", "<leader>" .. key, function()
        require("user.toggleterm")[entry[1]]()
    end, entry[2])
end
map("n", "<leader>lf", function()
    require("user.formatting").format()
end, "Format buffer")
map("n", "<leader>lF", function()
    require("user.formatting").toggle()
end, "Toggle buffer format-on-save")
map("n", "<leader>la", vim.lsp.buf.code_action, "Code action")
map("n", "<leader>lr", vim.lsp.buf.rename, "Rename")
map("n", "<leader>lh", function()
    vim.lsp.buf.signature_help({ border = "rounded" })
end, "Signature help")
map("n", "<leader>ll", vim.lsp.codelens.run, "Run CodeLens")
map("n", "<leader>lq", vim.diagnostic.setloclist, "Diagnostic location list")
map("n", "<leader>lj", function()
    vim.diagnostic.jump({ count = 1, float = true })
end, "Next diagnostic")
map("n", "<leader>lk", function()
    vim.diagnostic.jump({ count = -1, float = true })
end, "Previous diagnostic")
