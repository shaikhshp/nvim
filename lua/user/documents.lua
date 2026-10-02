vim.g.mkdp_filetypes = { "markdown" }
local ok, glow = pcall(require, "glow")
if ok then
    glow.setup({})
end
