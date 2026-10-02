local ok, dap = pcall(require, "dap")
if not ok then
    return
end

dap.adapters.codelldb = function(callback)
    local command = vim.fn.stdpath("data") .. "/mason/bin/codelldb"
    if vim.fn.has("win32") == 1 then
        command = command .. ".exe"
    end
    if vim.fn.executable(command) ~= 1 then
        vim.notify("Install Mason codelldb before debugging Rust", vim.log.levels.WARN)
        return
    end
    callback({
        type = "server",
        port = "${port}",
        executable = { command = command, args = { "--port", "${port}" } },
    })
end

local function root()
    return vim.fs.root(0, "Cargo.toml") or vim.fn.getcwd()
end

local function artifact(tests, project)
    project = project or root()
    -- DAP resumes this coroutine with its own run coroutine. Resume that only
    -- after Cargo and the asynchronous artifact picker have both completed.
    return coroutine.create(function(run)
        if vim.fn.executable("cargo") ~= 1 then
            vim.notify("Cargo is unavailable", vim.log.levels.WARN)
            coroutine.resume(run, dap.ABORT)
            return
        end
        local args = { "cargo", tests and "test" or "build", "--message-format=json" }
        if tests then
            args[#args + 1] = "--no-run"
        end
        vim.system(args, { cwd = project, text = true }, function(result)
            vim.schedule(function()
                if result.code ~= 0 then
                    local messages = {}
                    for line in (result.stdout or ""):gmatch("[^\r\n]+") do
                        local parsed, item = pcall(vim.json.decode, line)
                        if parsed and item.reason == "compiler-message" and item.message.rendered then
                            messages[#messages + 1] = item.message.rendered
                        end
                    end
                    vim.notify(
                        "Cargo failed:\n" .. table.concat(messages, "\n") .. (result.stderr or ""),
                        vim.log.levels.ERROR
                    )
                    coroutine.resume(run, dap.ABORT)
                    return
                end
                local artifacts, seen = {}, {}
                for line in (result.stdout or ""):gmatch("[^\r\n]+") do
                    local parsed, item = pcall(vim.json.decode, line)
                    if
                        parsed
                        and item.reason == "compiler-artifact"
                        and type(item.executable) == "string"
                        and item.executable ~= ""
                        and (not not item.profile.test) == tests
                        and not seen[item.executable]
                    then
                        seen[item.executable] = true
                        artifacts[#artifacts + 1] = { path = item.executable, name = item.target.name }
                    end
                end
                if #artifacts == 0 then
                    vim.notify("Cargo produced no debuggable artifacts", vim.log.levels.WARN)
                    coroutine.resume(run, dap.ABORT)
                elseif #artifacts == 1 then
                    coroutine.resume(run, artifacts[1].path)
                else
                    vim.ui.select(artifacts, {
                        prompt = tests and "Debug Rust test:" or "Debug Rust binary:",
                        format_item = function(item)
                            return item.name .. " (" .. item.path .. ")"
                        end,
                    }, function(item)
                        coroutine.resume(run, item and item.path or dap.ABORT)
                    end)
                end
            end)
        end)
    end)
end

local function config(tests)
    return setmetatable({
        name = tests and "Cargo tests" or "Cargo binary",
        type = "codelldb",
        request = "launch",
        program = function()
            return artifact(tests)
        end,
        cwd = root,
        stopOnEntry = false,
        args = {},
    }, {
        __call = function(self)
            local project = root()
            return vim.tbl_extend("force", self, {
                cwd = project,
                program = function()
                    return artifact(tests, project)
                end,
            })
        end,
    })
end

dap.configurations.rust = { config(false), config(true) }
local function maps(bufnr)
    vim.keymap.set("n", "<leader>Rb", function()
        dap.run(config(false))
    end, { buffer = bufnr, silent = true, desc = "Rust build and debug binary" })
    vim.keymap.set("n", "<leader>Rt", function()
        dap.run(config(true))
    end, { buffer = bufnr, silent = true, desc = "Rust build and debug tests" })
end
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("UserRustDap", { clear = true }),
    pattern = "rust",
    callback = function(event)
        maps(event.buf)
    end,
})
for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].filetype == "rust" then
        maps(bufnr)
    end
end
