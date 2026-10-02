vim.g.vimtex_view_method = "zathura"
vim.g.vimtex_compiler_method = "latexmk"
vim.g.vimtex_mappings_prefix = "<localleader>v"
vim.g.vimtex_quickfix_mode = 0
local options = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "-file-line-error" }
if vim.env.NVIM_TEX_SHELL_ESCAPE == "1" then
    options[#options + 1] = "-shell-escape"
end
vim.g.vimtex_compiler_latexmk = { executable = "latexmk", options = options }

local commands = {
    xc = { "VimtexCompile", "Compile LaTeX" },
    xf = { "VimtexCompileSelected", "Compile selection" },
    xv = { "VimtexView", "View PDF" },
    xs = { "VimtexStop", "Stop compiler" },
    xx = { "VimtexClean", "Clean build files" },
    xe = { "VimtexErrors", "Compiler errors" },
    xz = { "VimtexContextMenu", "LaTeX context menu" },
    xl = { "VimtexCountLetters", "Count letters" },
    xw = { "VimtexCountWords", "Count words" },
    xt = { "VimtexStatus", "Compiler status" },
    xa = { "VimtexStopAll", "Stop all compilers" },
}
local group = vim.api.nvim_create_augroup("UserVimtex", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "tex", "plaintex", "bib" },
    callback = function(event)
        for key, entry in pairs(commands) do
            vim.keymap.set("n", "<leader>" .. key, "<cmd>" .. entry[1] .. "<CR>", {
                buffer = event.buf,
                silent = true,
                desc = entry[2],
            })
        end
    end,
})
