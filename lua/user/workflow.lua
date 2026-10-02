local cord_ok, cord = pcall(require, "cord")
if cord_ok then
    cord.setup({
        idle = { enabled = false },
        advanced = { discord = { reconnect = { enabled = true, initial = true, interval = 5000 } } },
    })
end

local leetcode_ok, leetcode = pcall(require, "leetcode")
if leetcode_ok then
    leetcode.setup({
        arg = "leetcode.nvim",
        lang = "python3",
        cn = { enabled = false },
        storage = { home = vim.fn.stdpath("data") .. "/leetcode" },
        logging = true,
    })
end
