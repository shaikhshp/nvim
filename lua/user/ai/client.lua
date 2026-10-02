local M = { url = "http://127.0.0.1:11434" }

function M.request(path, payload, callback)
    if vim.fn.executable("curl") ~= 1 then
        vim.schedule(function()
            callback(nil, "Local AI requires curl")
        end)
        return
    end
    local args = {
        "curl",
        "--disable",
        "--silent",
        "--show-error",
        "--fail",
        "--proxy",
        "",
        "--noproxy",
        "*",
        "--max-redirs",
        "0",
        "--proto",
        "=http",
        "--connect-timeout",
        "2",
        "--max-time",
        payload and "60" or "5",
    }
    if payload then
        vim.list_extend(args, { "--header", "Content-Type: application/json", "--data-binary", "@-" })
    end
    args[#args + 1] = M.url .. path
    local ok, job = pcall(
        vim.system,
        args,
        { text = true, stdin = payload and vim.json.encode(payload) or nil },
        function(result)
            vim.schedule(function()
                if result.code ~= 0 then
                    callback(nil, "Local Ollama request failed or timed out; check the service at " .. M.url)
                    return
                end
                if #(result.stdout or "") > 512 * 1024 then
                    callback(nil, "Local Ollama returned an oversized response")
                    return
                end
                local decoded, data = pcall(vim.json.decode, result.stdout or "")
                if not decoded or type(data) ~= "table" or data.error then
                    callback(nil, "Local Ollama returned an invalid response")
                    return
                end
                callback(data)
            end)
        end
    )
    if not ok then
        vim.schedule(function()
            callback(nil, "Unable to start the local Ollama request")
        end)
        return
    end
    return job
end

return M
