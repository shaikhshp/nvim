local ok, persistence = pcall(require, "persistence")
if not ok then
    return
end

-- Restore file layouts without restarting terminals or replaying options/mappings.
vim.opt.sessionoptions = { "buffers", "curdir", "folds", "tabpages", "winsize" }
persistence.setup({ need = 1, branch = true })
