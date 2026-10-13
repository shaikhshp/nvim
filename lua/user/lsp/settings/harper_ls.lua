local markers = { ".harper-dictionary.txt", ".git" }

return {
    filetypes = { "markdown", "text", "tex", "plaintex", "typst", "quarto", "gitcommit", "asciidoc", "html" },
    get_language_id = function(_, filetype)
        return ({ text = "plaintext", plaintex = "tex" })[filetype] or filetype
    end,
    settings = {
        ["harper-ls"] = {
            linters = { SpellCheck = true },
            diagnosticSeverity = "hint",
            dialect = "American",
            codeActions = { ForceStable = true },
        },
    },
    on_attach = function(client, bufnr)
        require("user.spelling").on_attach(client, bufnr)
    end,
    root_markers = markers,
    root_dir = function(bufnr, on_dir)
        require("user.spelling").root_dir(bufnr, on_dir, markers)
    end,
}
