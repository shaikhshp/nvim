local status_ok, npairs = pcall(require, "nvim-autopairs")
if not status_ok then
    return
end

npairs.setup({
    -- The pinned plugin's TS checks require APIs removed by rewritten Treesitter.
    check_ts = false,
    disable_filetype = { "TelescopePrompt", "spectre_panel", "vim" },
    fast_wrap = {
        map = "<M-e>",
        chars = { "{", "[", "(", "\"", "'" },
        pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
        offset = 0,
        end_key = "$",
        keys = "qwertyuiopzxcvbnmasdfghjkl",
        check_comma = true,
        highlight = "PmenuSel",
        highlight_grey = "LineNr",
    },
})

local cmp_status_ok, cmp = pcall(require, "cmp")
if not cmp_status_ok then
    return
end

local integration_ok, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
if integration_ok then
    if npairs.user_confirm_done then
        cmp.event:off("confirm_done", npairs.user_confirm_done)
    end
    npairs.user_confirm_done = cmp_autopairs.on_confirm_done({ filetypes = { tex = false } })
    cmp.event:on("confirm_done", npairs.user_confirm_done)
end
