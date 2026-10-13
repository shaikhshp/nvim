local markers = { "typos.toml", "_typos.toml", ".typos.toml", "pyproject.toml", "Cargo.toml", ".git" }

return {
    init_options = { diagnosticSeverity = "Hint" },
    cmd_env = { RUST_LOG = "typos_lsp=error" },
    on_attach = function(client, bufnr)
        require("user.spelling").on_attach(client, bufnr)
    end,
    -- Typos checks text tokens for known misspellings, not a full prose dictionary.
    filetypes = {
        "python",
        "lua",
        "rust",
        "java",
        "c",
        "cpp",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "sh",
        "bash",
        "zsh",
        "go",
        "ruby",
        "cs",
        "php",
        "kotlin",
        "css",
        "bib",
        "json",
        "jsonc",
        "yaml",
        "toml",
    },
    root_markers = markers,
    root_dir = function(bufnr, on_dir)
        require("user.spelling").root_dir(bufnr, on_dir, markers)
    end,
}
