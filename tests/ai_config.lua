-- Run: nvim --headless -u NONE -i NONE -l tests/ai_config.lua
-- No provider, plugin installation, Ollama service, or user files are needed.
vim.opt.runtimepath:append(vim.fn.getcwd())
vim.opt.hidden = true
vim.g.mapleader = " "
local api = vim.api
local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/project/.git", "p")
vim.fn.mkdir(root .. "/outside", "p")
local project = root .. "/project"
local saved = {
    notify = vim.notify,
    system = vim.system,
    packadd = vim.cmd.packadd,
    get_node = vim.treesitter.get_node,
    get_clients = vim.lsp.get_clients,
    select = vim.ui.select,
    schedule = vim.schedule,
}
-- Drain explicit turns rather than entering the headless input loop in Insert mode.
local scheduled = {}
vim.schedule = function(callback)
    scheduled[#scheduled + 1] = callback
end
local function turn()
    local callbacks = scheduled
    scheduled = {}
    for _, callback in ipairs(callbacks) do
        callback()
    end
end
local notices, requests, plugin_calls, formatted = {}, {}, {}, {}
local network, loads, passed, failures = 0, 0, 0, {}
vim.notify = function(message)
    notices[#notices + 1] = message
end
vim.system = function()
    network = network + 1
    error("Unexpected real process/network request")
end
vim.cmd.packadd = function()
    loads = loads + 1
    error("Unexpected plugin load")
end
local function equal(actual, expected, message)
    assert(
        vim.deep_equal(actual, expected),
        (message or "Values differ") .. "\nactual: " .. vim.inspect(actual) .. "\nexpected: " .. vim.inspect(expected)
    )
end
local function test(name, callback)
    local ok, err = xpcall(callback, debug.traceback)
    if ok then
        passed = passed + 1
        print("PASS: " .. name)
    else
        failures[#failures + 1] = name .. "\n" .. err
        print("FAIL: " .. name .. "\n" .. err)
    end
end
local function write(relative, lines)
    local path = root .. "/" .. relative
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    assert(vim.fn.writefile(lines, path) == 0)
    return path
end
local function buffer(relative, lines)
    local path = write("project/" .. relative, lines or { "local value = 1", "return value", "-- tail" })
    local buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
    api.nvim_set_current_buf(buf)
    vim.bo[buf].filetype = "lua"
    api.nvim_win_set_cursor(0, { 1, 0 })
    return buf
end
local function lines(buf)
    return api.nvim_buf_get_lines(buf, 0, -1, false)
end
local function normal()
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
end
local function in_insert(callback)
    local result
    _G.AIConfigTestInsert = function()
        result = {
            xpcall(function()
                equal(vim.fn.mode(), "i", "Fixture must enter real Insert mode")
                callback()
            end, debug.traceback),
        }
    end
    api.nvim_feedkeys(
        api.nvim_replace_termcodes("i<Cmd>lua AIConfigTestInsert()<CR><Esc>", true, false, true),
        "nx",
        false
    )
    _G.AIConfigTestInsert = nil
    assert(result and result[1], result and result[2] or "Insert-mode callback did not run")
end
local tags = {
    models = {
        { name = "qwen2.5-coder:3b" },
        { name = "qwen2.5-coder:7b" },
        { name = "qwen2.5-coder:3b-8k", remote_host = "cloud.example" },
        { name = "qwen2.5-coder:7b-16k", remote_model = "cloud" },
        { name = "unknown:latest" },
    },
}
package.loaded["user.ai.client"] = {
    request = function(path, payload, callback)
        local request = { path = path, payload = payload, callback = callback, killed = false }
        function request:kill(signal)
            equal(signal, 15)
            self.killed = true
        end
        requests[#requests + 1] = request
        return request
    end,
}
package.loaded["user.ai.plugins"] = {
    cancel = function()
        plugin_calls[#plugin_calls + 1] = { "cancel" }
    end,
    chat = function(text, settings)
        plugin_calls[#plugin_calls + 1] = { "chat", text, settings }
        return true
    end,
    completion = function(action, settings)
        plugin_calls[#plugin_calls + 1] = { "completion", action, settings }
        return true
    end,
}
package.loaded["user.formatting"] = {
    format = function(buf)
        formatted[#formatted + 1] = buf
        return true
    end,
}
local function deliver(request, data, err)
    assert(request and not request.delivered, "Missing or already delivered callback")
    request.delivered = true
    vim.schedule(function()
        request.callback(data, err)
    end)
    turn()
end
local tab_mapping = function() end
vim.keymap.set("i", "<Tab>", tab_mapping, { desc = "Existing cmp Tab" })
vim.keymap.set("i", "<S-Tab>", tab_mapping, { desc = "Existing cmp Shift-Tab" })
local tab_before = vim.fn.maparg("<Tab>", "i", false, true)
local shift_before = vim.fn.maparg("<S-Tab>", "i", false, true)
local cmp = { sentinel = "existing cmp" }
package.loaded.cmp = cmp
local ai = require("user.ai")
local context = require("user.ai.context")
local lsp_namespace = api.nvim_create_namespace("AIConfigTestLSP")
local function start(action, scope)
    local count = #requests
    ai.run(action or "review", scope or "buffer")
    equal(#requests, count + 1)
    local discovery = requests[#requests]
    equal(discovery.path, "/api/tags")
    equal(discovery.payload, nil)
    deliver(discovery, tags)
    equal(#requests, count + 2)
    local request = requests[#requests]
    equal(request.path, "/api/chat")
    equal(request.payload.stream, false)
    return request
end
local function answer(request, value, raw)
    deliver(request, { message = { content = raw and value or vim.json.encode(value) } })
end
local function findings(line)
    return { findings = { { line = line or 1, message = "Possible defect", suggestion = "Check the value" } } }
end

test("startup is inert and preserves cmp/Tab mappings", function()
    equal(network, 0)
    equal(loads, 0)
    equal(#requests, 0)
    equal(#plugin_calls, 0)
    equal(package.loaded.cmp, cmp)
    equal(vim.fn.maparg("<Tab>", "i", false, true), tab_before)
    equal(vim.fn.maparg("<S-Tab>", "i", false, true), shift_before)
    for _, key in ipairs({ "<M-y>", "<M-CR>", "<M-l>", "<M-]>", "<M-[>", "<M-x>" }) do
        assert(type(vim.fn.maparg(key, "i", false, true).callback) == "function", "Missing " .. key)
    end
    for _, event in ipairs({ "InsertEnter", "CursorMovedI", "TextChangedI" }) do
        api.nvim_exec_autocmds(event, { buffer = api.nvim_get_current_buf() })
    end
    equal(#requests, 0)
    equal(#plugin_calls, 0)
    assert(package.loaded.minuet == nil and package.loaded.codecompanion == nil)
end)

test("secret/generated/notebook and buffer eligibility blocks all requests", function()
    for _, path in ipairs({
        ".env",
        ".env.local",
        "private.key",
        "credentials.json",
        ".ssh/id_rsa",
        "node_modules/a.lua",
        "target/a.lua",
        "dist/a.lua",
        "vendor/a.lua",
        ".git/a.lua",
        "a.ipynb",
    }) do
        local buf = buffer(path)
        local count = #requests
        assert(not context.eligible(buf), path)
        ai.run("review", "buffer")
        equal(#requests, count, path .. " must not reach model discovery")
    end
    local buf = buffer("blocked.lua")
    for _, option in ipairs({ "readonly", "modifiable", "buftype", "disable_local_ai", "oversize" }) do
        if option == "readonly" then
            vim.bo[buf].readonly = true
        elseif option == "modifiable" then
            vim.bo[buf].modifiable = false
        elseif option == "buftype" then
            vim.bo[buf].buftype = "nofile"
        elseif option == "disable_local_ai" then
            vim.b[buf].disable_local_ai = true
        else
            api.nvim_buf_set_lines(buf, 0, -1, false, { string.rep("x", context.max_bytes + 1) })
        end
        assert(not context.eligible(buf), option)
        local count = #requests
        ai.run("review", "buffer")
        equal(#requests, count)
        vim.bo[buf].readonly = false
        vim.bo[buf].modifiable = true
        vim.bo[buf].buftype = ""
        vim.b[buf].disable_local_ai = false
    end
    api.nvim_buf_set_lines(buf, 0, -1, false, { "ok" })
    assert(context.eligible(buf))
end)

test("unsaved files beneath vendor and .ssh aliases are excluded without requests", function()
    local count = #requests
    local source = { "local unsaved = true", "return unsaved" }
    for _, target in ipairs({ "vendor", ".ssh" }) do
        local alias = project .. "/unsaved-alias-" .. (target == "vendor" and "library" or "private")
        vim.fn.mkdir(project .. "/" .. target, "p")
        assert(vim.uv.fs_symlink(project .. "/" .. target, alias))
        for _, suffix in ipairs({ "new-unsaved.lua", "missing/deeper/new-unsaved.lua" }) do
            local path, canonical = alias .. "/" .. suffix, project .. "/" .. target .. "/" .. suffix
            assert(vim.uv.fs_stat(path) == nil and vim.uv.fs_stat(canonical) == nil)
            local buf = api.nvim_create_buf(true, false)
            api.nvim_buf_set_name(buf, path)
            api.nvim_set_current_buf(buf)
            api.nvim_buf_set_lines(buf, 0, -1, false, source)
            equal(vim.bo[buf].buftype, "")
            assert(vim.bo[buf].modifiable and not vim.bo[buf].readonly)
            assert(not context.eligible(buf), "Unsaved alias into " .. target .. " must be excluded")
            assert(not context.snapshot("buffer"))
            ai.run("review", "buffer")
            equal(#requests, count, "Excluded unsaved paths must not request model discovery")
            equal(lines(buf), source)
            assert(vim.uv.fs_stat(path) == nil and vim.uv.fs_stat(canonical) == nil)
        end
    end
    local path = project .. "/new-project-directory/nested/unsaved.lua"
    assert(vim.uv.fs_stat(path) == nil)
    local buf = api.nvim_create_buf(true, false)
    api.nvim_buf_set_name(buf, path)
    api.nvim_set_current_buf(buf)
    api.nvim_buf_set_lines(buf, 0, -1, false, source)
    assert(context.eligible(buf), "Ordinary named unsaved project files must remain eligible")
    local snapshot = assert(context.snapshot("buffer"))
    equal(snapshot.lines, source)
    assert(context.current(snapshot))
    equal(#requests, count)
    assert(vim.uv.fs_stat(path) == nil, "Eligibility and snapshots must never save unsaved files")
    equal(network, 0)
end)

test("extra context stays in project and rejects symlink escape and excluded files", function()
    buffer("context.lua")
    context.extra_files = {}
    write("outside/escape.lua", { "outside secret" })
    assert(vim.uv.fs_symlink(root .. "/outside/escape.lua", project .. "/escape.lua"))
    assert(not context.add_file("escape.lua"))
    assert(not context.add_file("../outside/escape.lua"))
    assert(not context.add_file(".env"))
    assert(not context.add_file("dist/a.lua"))
    assert(not context.add_file("a.ipynb"))
    write("project/extra.lua", { "local attached = true" })
    assert(context.add_file("extra.lua"))
    assert(not context.add_file("extra.lua"))
    equal(#context.extra_files, 1)
    local text = assert(context.render(assert(context.snapshot("buffer"))))
    assert(text:find("Explicit context file: extra.lua", 1, true))
    assert(text:find("local attached = true", 1, true))
    assert(not text:find("outside secret", 1, true))
end)

test("secret-named context symlinks cannot bypass path exclusions", function()
    buffer("alias-context.lua")
    context.extra_files = {}
    write("project/ordinary.txt", { "must not be attached through a secret-named path" })
    assert(vim.uv.fs_symlink(project .. "/ordinary.txt", project .. "/.env.alias"))
    local ok = context.add_file(".env.alias")
    local attached = #context.extra_files
    context.extra_files = {}
    assert(not ok and attached == 0, "add_file accepted .env.alias after resolving its symlink to ordinary.txt")
    write("project/.env.canonical", { "canonical secret" })
    assert(vim.uv.fs_symlink(project .. "/.env.canonical", project .. "/ordinary-alias.txt"))
    assert(not context.add_file("ordinary-alias.txt"), "Canonical secret paths must also be excluded")
    equal(#context.extra_files, 0)
end)

test("function/selection snapshots use real ranges, copy source and diagnostics", function()
    local buf = buffer("snapshot.lua", { "-- header", "local function f()", "    return 1", "end", "-- tail" })
    local node = {
        type = function()
            return "function_declaration"
        end,
        range = function()
            return 1, 0, 4, 0
        end,
    }
    vim.treesitter.get_node = function()
        return node
    end
    vim.diagnostic.set(lsp_namespace, buf, { { lnum = 2, col = 0, message = "LSP issue", source = "pyright" } })
    vim.diagnostic.set(ai.namespace, buf, { { lnum = 2, col = 0, message = "Old hint", source = "Ollama Review" } })
    local snapshot = assert(context.snapshot("function"))
    equal({ snapshot.first, snapshot.last }, { 2, 4 })
    equal(snapshot.lines, { "local function f()", "    return 1", "end" })
    equal(#snapshot.diagnostics, 1)
    equal(snapshot.diagnostics[1].source, "pyright")
    assert(context.current(snapshot))
    api.nvim_buf_set_lines(buf, 2, 3, false, { "    return 2" })
    equal(snapshot.lines[2], "    return 1")
    assert(not context.current(snapshot))
    vim.treesitter.get_node = saved.get_node
    api.nvim_win_set_cursor(0, { 4, 0 })
    api.nvim_feedkeys("Vkk", "nx!", false)
    equal(vim.fn.mode(), "V")
    local selection = assert(context.snapshot("selection"))
    equal({ selection.first, selection.last }, { 2, 4 })
    normal()
    assert(not context.snapshot("selection"))
end)

test("render byte budget includes additional files and their wrappers", function()
    buffer("budget.lua", { string.rep("x", 5000) })
    context.extra_files = {}
    for i = 1, 3 do
        write("project/budget" .. i .. ".lua", { string.rep("y", 2400) })
        assert(context.add_file("budget" .. i .. ".lua"))
    end
    local snapshot = assert(context.snapshot("buffer"))
    assert(not context.render(snapshot), "Combined source and attachments must exceed 12,000 bytes")
    context.extra_files = {}
    local text = assert(context.render(snapshot))
    local budget = context.budget
    context.budget = #text
    assert(context.render(snapshot), "Exact byte limit should be accepted")
    context.budget = #text - 1
    assert(not context.render(snapshot))
    context.budget = budget
    write("project/large-extra.lua", { string.rep("z", 4001) })
    assert(not context.add_file("large-extra.lua"))
end)

test("extra context caps attachments and captures loaded unsaved content", function()
    local source = buffer("attachments.lua")
    context.extra_files = {}
    local extra = buffer("loaded-extra.lua", { "disk value" })
    api.nvim_buf_set_lines(extra, 0, -1, false, { "unsaved value" })
    api.nvim_set_current_buf(source)
    assert(context.add_file("loaded-extra.lua"))
    equal(context.extra_files[1].text, "unsaved value")
    equal(vim.fn.readfile(api.nvim_buf_get_name(extra)), { "disk value" })
    for i = 1, 3 do
        write("project/attachment" .. i .. ".lua", { "small file" })
        local ok = context.add_file("attachment" .. i .. ".lua")
        equal(ok, i < 3, "At most three attachments are allowed")
    end
    equal(#context.extra_files, 3)
    local snapshot = assert(context.snapshot("buffer"))
    snapshot.root = root .. "/outside"
    assert(not assert(context.render(snapshot)):find("unsaved value", 1, true), "Attachments must not cross projects")
    context.extra_files = {}
    api.nvim_buf_set_lines(extra, 0, -1, false, { string.rep("x", 4001) })
    assert(not context.add_file("loaded-extra.lua"), "Loaded extra buffers still have a 4,000-byte limit")
end)

test("review publishes separate Ollama Review HINTs and preserves LSP diagnostics", function()
    local buf = buffer("review.lua")
    local before = lines(buf)
    vim.diagnostic.set(lsp_namespace, buf, {
        {
            lnum = 0,
            col = 0,
            message = "Compiler error",
            source = "test-lsp",
            severity = vim.diagnostic.severity.ERROR,
        },
    })
    local lsp = vim.diagnostic.get(buf, { namespace = lsp_namespace })
    answer(start(), findings(2))
    local hints = vim.diagnostic.get(buf, { namespace = ai.namespace })
    equal(#hints, 1)
    equal(hints[1].source, "Ollama Review")
    equal(hints[1].severity, vim.diagnostic.severity.HINT)
    equal(hints[1].lnum, 1)
    equal(vim.diagnostic.get(buf, { namespace = lsp_namespace }), lsp)
    equal(lines(buf), before)
    ai.clear()
    equal(#vim.diagnostic.get(buf, { namespace = ai.namespace }), 0)
    equal(vim.diagnostic.get(buf, { namespace = lsp_namespace }), lsp)
end)

test("invalid review output is atomic, never edits source or replaces existing hints", function()
    local buf = buffer("invalid.lua")
    local before = lines(buf)
    answer(start(), findings())
    local existing = vim.diagnostic.get(buf, { namespace = ai.namespace })
    local many = {}
    for _ = 1, 13 do
        many[#many + 1] = findings().findings[1]
    end
    local invalid = { { findings = many }, { findings = { line = 1 } } }
    for _, line in ipairs({ 0, -1, 4, 1.5, "1", vim.NIL }) do
        invalid[#invalid + 1] = findings(line)
    end
    invalid[#invalid + 1] = { findings = { findings().findings[1], { line = 99, message = "bad", suggestion = "" } } }
    invalid[#invalid + 1] = { findings = { { line = 1, message = string.rep("m", 1001), suggestion = "" } } }
    invalid[#invalid + 1] = { findings = { { line = 1, message = "bad", suggestion = string.rep("s", 2001) } } }
    invalid[#invalid + 1] = { findings = { { line = 1, message = "missing suggestion" } } }
    invalid[#invalid + 1] = { findings = { vim.NIL } }
    invalid[#invalid + 1] = { findings = vim.NIL }
    for _, value in ipairs(invalid) do
        answer(start(), value)
        equal(lines(buf), before)
        equal(vim.diagnostic.get(buf, { namespace = ai.namespace }), existing)
    end
    for _, raw in ipairs({ "{broken", "null", "42", string.rep("x", context.max_bytes + 1) }) do
        answer(start(), raw, true)
        equal(lines(buf), before)
        equal(vim.diagnostic.get(buf, { namespace = ai.namespace }), existing)
    end
    answer(start(), { findings = {} })
    equal(#vim.diagnostic.get(buf, { namespace = ai.namespace }), 0)
end)

test("stale discovery and responses after edit, switch, cancel are dropped", function()
    for _, stage in ipairs({ "discovery", "response" }) do
        for _, change in ipairs({ "edit", "switch", "cancel" }) do
            local buf = buffer("stale-" .. stage .. "-" .. change .. ".lua")
            local count = #requests
            ai.run("review", "buffer")
            local request = requests[#requests]
            if stage == "response" then
                deliver(request, tags)
                request = requests[#requests]
            end
            if change == "edit" then
                api.nvim_buf_set_lines(buf, 0, 1, false, { "user edit" })
            elseif change == "switch" then
                buffer("other-" .. stage .. ".lua")
            else
                ai.cancel()
                assert(request.killed, "Cancellation must kill the pending asynchronous job")
            end
            if stage == "discovery" then
                deliver(request, tags)
                equal(#requests, count + 1)
            else
                answer(request, findings())
            end
            equal(#vim.diagnostic.get(buf, { namespace = ai.namespace }), 0)
            equal(lines(buf)[1], change == "edit" and "user edit" or "local value = 1")
        end
    end
end)

test("source edit events kill pending discovery and requests without late hints or fallback", function()
    for _, stage in ipairs({ "discovery", "response" }) do
        for _, event in ipairs({ "TextChanged", "TextChangedI" }) do
            local buf = buffer("auto-cancel-" .. stage .. "-" .. event .. ".lua")
            vim.diagnostic.set(lsp_namespace, buf, {
                {
                    lnum = 0,
                    col = 0,
                    message = "Compiler error survives cancellation",
                    source = "test-compiler",
                    severity = vim.diagnostic.severity.ERROR,
                },
            })
            local compiler = vim.diagnostic.get(buf, { namespace = lsp_namespace })
            answer(start(), findings())
            equal(#vim.diagnostic.get(buf, { namespace = ai.namespace }), 1)
            ai.run("review", "buffer")
            local request = requests[#requests]
            if stage == "response" then
                deliver(request, tags)
                request = requests[#requests]
            end
            assert(not request.killed)
            local count, calls = #requests, #plugin_calls
            api.nvim_buf_set_lines(buf, 0, 1, false, { "user edit while request is active" })
            -- API edits do not synchronously fire TextChanged; dispatch the real autocmd explicitly.
            api.nvim_exec_autocmds(event, { buffer = buf })
            assert(request.killed, stage .. " must be terminated on " .. event)
            equal(#plugin_calls, calls + 1)
            equal(plugin_calls[#plugin_calls], { "cancel" })
            equal(#vim.diagnostic.get(buf, { namespace = ai.namespace }), 0)
            equal(vim.diagnostic.get(buf, { namespace = lsp_namespace }), compiler)
            if stage == "discovery" then
                deliver(request, tags)
            else
                answer(request, findings())
            end
            turn()
            equal(#requests, count, "Cancelled requests must never retry or fall back")
            equal(#plugin_calls, calls + 1, "Late callbacks must not invoke a plugin")
            equal(#vim.diagnostic.get(buf, { namespace = ai.namespace }), 0)
            equal(vim.diagnostic.get(buf, { namespace = lsp_namespace }), compiler)
            equal(lines(buf)[1], "user edit while request is active")
        end
    end
end)

test("cancel_pending drops core callbacks without cancelling a submitting plugin chat", function()
    for _, stage in ipairs({ "discovery", "response" }) do
        local buf = buffer("core-only-cancel-" .. stage .. ".lua")
        local before = lines(buf)
        vim.diagnostic.set(lsp_namespace, buf, {
            {
                lnum = 0,
                col = 0,
                message = "Compiler issue survives core cancellation",
                source = "test-compiler",
                severity = vim.diagnostic.severity.ERROR,
            },
        })
        local compiler = vim.diagnostic.get(buf, { namespace = lsp_namespace })
        local snapshot = assert(context.snapshot("buffer"))
        ai.run("review", "buffer")
        local request = requests[#requests]
        if stage == "response" then
            deliver(request, tags)
            request = requests[#requests]
        end
        assert(not request.killed)
        -- Stand in for a chat submitting independently of the core review request.
        package.loaded["user.ai.plugins"].chat("submitting synthetic chat", { review_model = "qwen2.5-coder:3b" })
        local count, calls = #requests, vim.deepcopy(plugin_calls)
        ai.cancel_pending()
        assert(request.killed, "Core-only cancellation must terminate " .. stage)
        equal(plugin_calls, calls, "Core cancellation must not stop the submitting chat or other plugin work")
        assert(context.current(snapshot), "Source must remain current so generation guards reject late results")
        ai.cancel_pending()
        api.nvim_exec_autocmds("TextChanged", { buffer = buf })
        equal(plugin_calls, calls, "Core cancellation must clear pending_source and be idempotent")
        if stage == "discovery" then
            deliver(request, tags)
        else
            answer(request, findings())
        end
        turn()
        equal(#requests, count, "Cancelled discovery must not submit inference or retry")
        equal(plugin_calls, calls, "Late core callbacks must not affect the submitting plugin chat")
        equal(#vim.diagnostic.get(buf, { namespace = ai.namespace }), 0)
        equal(vim.diagnostic.get(buf, { namespace = lsp_namespace }), compiler)
        equal(lines(buf), before)
    end
end)

test("unavailable Ollama never retries, falls back, edits source, or changes compiler diagnostics", function()
    local buf = buffer("unavailable.lua")
    local before = lines(buf)
    vim.diagnostic.set(lsp_namespace, buf, {
        {
            lnum = 1,
            col = 0,
            message = "Real compiler issue",
            source = "test-compiler",
            severity = vim.diagnostic.severity.ERROR,
        },
    })
    local compiler = vim.diagnostic.get(buf, { namespace = lsp_namespace })
    for _, action in ipairs({ "review", "fix", "explain", "chat" }) do
        for _, failure in ipairs({ "unavailable", "not-installed" }) do
            local count, calls = #requests, #plugin_calls
            ai.run(action, "buffer")
            equal(#requests, count + 1)
            if failure == "unavailable" then
                deliver(requests[#requests], nil, "Local Ollama unavailable")
            else
                deliver(requests[#requests], { models = {} })
            end
            turn()
            equal(#requests, count + 1, "Discovery failure must not issue an inference/fallback request")
            equal(#plugin_calls, calls + 1)
            equal(plugin_calls[#plugin_calls], { "cancel" })
            equal(lines(buf), before)
            equal(vim.diagnostic.get(buf, { namespace = lsp_namespace }), compiler)
            equal(#vim.diagnostic.get(buf, { namespace = ai.namespace }), 0)
        end
    end
    for _, action in ipairs({ "review", "fix", "explain" }) do
        local request = start(action)
        local count, calls = #requests, #plugin_calls
        deliver(request, nil, "Local Ollama request failed or timed out")
        turn()
        equal(#requests, count, "Inference errors must not retry or select a fallback model")
        equal(#plugin_calls, calls)
        equal(lines(buf), before)
        equal(vim.diagnostic.get(buf, { namespace = lsp_namespace }), compiler)
        equal(#vim.diagnostic.get(buf, { namespace = ai.namespace }), 0)
    end
    equal(api.nvim_get_current_buf(), buf)
    equal(#api.nvim_list_tabpages(), 1)
end)

test("fix diff scratches never edit source until accept, rejection and stale accept are safe", function()
    local buf = buffer("fix.lua", { "-- header", "local value = 1", "return value", "-- tail" })
    context.extra_files = {}
    local disk = vim.fn.readfile(api.nvim_buf_get_name(buf))
    local function preview()
        api.nvim_set_current_buf(buf)
        api.nvim_win_set_cursor(0, { 2, 0 })
        api.nvim_feedkeys("Vj", "nx!", false)
        local request = start("fix", "selection")
        answer(request, { explanation = "Correct the selected value", replacement = "local value = 2\nreturn value\n" })
        local tabs = api.nvim_list_tabpages()
        equal(#tabs, 2)
        local windows = api.nvim_tabpage_list_wins(api.nvim_get_current_tabpage())
        equal(#windows, 2)
        for _, win in ipairs(windows) do
            local scratch = api.nvim_win_get_buf(win)
            equal(vim.bo[scratch].buftype, "nofile")
            equal(vim.bo[scratch].modifiable, false)
            assert(vim.wo[win].diff)
            assert(scratch ~= buf)
        end
    end
    preview()
    equal(lines(buf), disk)
    equal(#formatted, 0)
    ai.reject()
    equal(lines(buf), disk)
    equal(#api.nvim_list_tabpages(), 1)
    preview()
    api.nvim_buf_set_lines(buf, 1, 2, false, { "local value = 9" })
    assert(ai.accept() == false)
    equal(lines(buf), { "-- header", "local value = 9", "return value", "-- tail" })
    equal(#formatted, 0)
    api.nvim_buf_set_lines(buf, 1, 2, false, { "local value = 1" })
    preview()
    assert(ai.accept())
    equal(lines(buf), { "-- header", "local value = 2", "return value", "-- tail" })
    equal(formatted, { buf })
    assert(vim.bo[buf].modified)
    equal(vim.fn.readfile(api.nvim_buf_get_name(buf)), disk, "Acceptance must not save the file")
end)

test("malformed corrections create no preview and never edit source", function()
    local buf = buffer("invalid-fix.lua")
    local before = lines(buf)
    local count = #formatted
    for _, value in ipairs({
        { explanation = "missing replacement" },
        { explanation = 42, replacement = "changed" },
        { explanation = "bad replacement", replacement = vim.NIL },
        { explanation = "oversize", replacement = string.rep("x", context.max_bytes + 1) },
    }) do
        answer(start("fix"), value)
        equal(lines(buf), before)
        equal(#api.nvim_list_tabpages(), 1)
        equal(api.nvim_get_current_buf(), buf)
        equal(#formatted, count)
    end
end)

test("correction prefixes, wrappers and fences are rejected without source or diagnostic edits", function()
    local buf = buffer("wrapped-fix.lua")
    local before, tick = lines(buf), api.nvim_buf_get_changedtick(buf)
    local disk = vim.fn.readfile(api.nvim_buf_get_name(buf))
    local modified, count = vim.bo[buf].modified, #formatted
    vim.diagnostic.set(lsp_namespace, buf, {
        {
            lnum = 0,
            col = 0,
            message = "Compiler diagnostic remains authoritative",
            source = "test-compiler",
            severity = vim.diagnostic.severity.ERROR,
        },
    })
    local compiler = vim.diagnostic.get(buf, { namespace = lsp_namespace })
    for _, marker in ipairs({
        "1 | local value = 2",
        "  2| return value",
        "```lua",
        " ``` ",
        "<source>",
        "</source>",
        " <header> ",
        "</header>",
        "<additional-source>",
        " </additional-source> ",
    }) do
        local request = start("fix")
        answer(request, {
            explanation = "A wrapped replacement must be rejected",
            replacement = "local value = 2\r\n" .. marker .. "\r\nreturn value\r\n",
        })
        local tabs, current = #api.nvim_list_tabpages(), api.nvim_get_current_buf()
        local notice = notices[#notices]
        ai.reject()
        equal(tabs, 1, "Rejected marker must not create a diff preview: " .. marker)
        equal(current, buf)
        assert(notice:find("Correction rejected:", 1, true), "Expected explicit rejection for " .. marker)
        assert(ai.accept() == nil, "Rejected corrections must not leave an acceptable preview")
        equal(lines(buf), before)
        equal(api.nvim_buf_get_changedtick(buf), tick, "Rejected corrections must not touch source")
        equal(vim.bo[buf].modified, modified)
        equal(vim.fn.readfile(api.nvim_buf_get_name(buf)), disk)
        equal(#formatted, count)
        equal(vim.diagnostic.get(buf, { namespace = lsp_namespace }), compiler)
        equal(#vim.diagnostic.get(buf, { namespace = ai.namespace }), 0)
    end
end)

test("model switching only accepts exact installed approved non-cloud tags", function()
    local buf = buffer("models.lua")
    ai.pick_model("qwen2.5-coder:7b")
    deliver(requests[#requests], { models = { { name = "qwen2.5-coder:3b" } } })
    equal(start().payload.model, "qwen2.5-coder:3b", "Approved but uninstalled tags must be refused")
    answer(requests[#requests], { findings = {} })
    ai.pick_model("qwen2.5-coder:7b")
    deliver(requests[#requests], { models = "malformed model list" })
    equal(start().payload.model, "qwen2.5-coder:3b", "Malformed model discovery must not change the selection")
    answer(requests[#requests], { findings = {} })
    for _, tag in ipairs({
        "unknown:latest",
        "qwen2.5-coder",
        "qwen2.5-coder:3b-8k",
        "qwen2.5-coder:7b-16k",
        "qwen2.5-coder:7b ",
        "qwen2.5-coder:99b",
    }) do
        ai.pick_model(tag)
        deliver(requests[#requests], tags)
        equal(start().payload.model, "qwen2.5-coder:3b", "Rejected tag changed the model: " .. tag)
        answer(requests[#requests], { findings = {} })
    end
    ai.pick_model("qwen2.5-coder:7b")
    deliver(requests[#requests], tags)
    local count = #requests
    ai.run("review", "buffer")
    deliver(requests[#requests], { models = { { name = "qwen2.5-coder:3b" } } })
    equal(#requests, count + 1, "A missing selected model must not fall back or submit a chat request")
    equal(start().payload.model, "qwen2.5-coder:7b")
    answer(requests[#requests], { findings = {} })
    vim.ui.select = function(choices, _, callback)
        equal(choices, { "qwen2.5-coder:3b", "qwen2.5-coder:7b" })
        callback("qwen2.5-coder:3b")
    end
    ai.pick_model()
    deliver(requests[#requests], tags)
    vim.ui.select = saved.select
    equal(start().payload.model, "qwen2.5-coder:3b")
    answer(requests[#requests], { findings = {} })
    equal(api.nvim_get_current_buf(), buf)
end)

test("completion mappings are explicit and discovery is guarded", function()
    local buf = buffer("completion.lua")
    local callback = vim.fn.maparg("<M-y>", "i", false, true).callback
    in_insert(function()
        local count = #requests
        callback()
        equal(#requests, count + 1)
        local request = requests[#requests]
        api.nvim_buf_set_lines(buf, 0, 1, false, { "changed while discovering" })
        local calls = #plugin_calls
        deliver(request, tags)
        equal(#plugin_calls, calls)
        callback()
        deliver(requests[#requests], tags)
        equal(plugin_calls[#plugin_calls][1], "completion")
        equal(plugin_calls[#plugin_calls][2], "next")
    end)
    local count = #requests
    callback()
    equal(#requests, count, "Normal mode must not discover completion models")
    equal(vim.fn.maparg("<Tab>", "i", false, true), tab_before)
    equal(package.loaded.cmp, cmp)
end)

-- Exercise the real plugin wrapper with only its external dependencies stubbed.
test("real plugin completion guards asynchronous results and scheduled accepts", function()
    normal()
    buffer("plugin.lua")
    package.loaded["user.ai.plugins"] = nil
    local plugins = require("user.ai.plugins")
    equal(loads, 0, "Requiring the wrapper must not packadd anything")
    local callbacks, received, visible, dismissed, setups = {}, 0, false, 0, 0
    local backend = {
        complete = function(_, callback)
            callbacks[#callbacks + 1] = callback
        end,
    }
    local virtualtext = {
        setup = function()
            setups = setups + 1
        end,
        action = {},
    }
    virtualtext.action.is_visible = function()
        return visible
    end
    virtualtext.action.dismiss = function()
        visible = false
        dismissed = dismissed + 1
    end
    virtualtext.action.next = function()
        backend.complete({}, function()
            received = received + 1
            visible = true
        end)
    end
    virtualtext.action.prev = virtualtext.action.next
    virtualtext.action.accept = function()
        vim.schedule(function()
            api.nvim_buf_set_lines(0, 0, 1, false, { "accepted completion" })
        end)
    end
    virtualtext.action.accept_line = virtualtext.action.accept
    local minuet = {
        setup = function()
            error("Top-level Minuet setup must never run")
        end,
    }
    package.loaded.minuet = minuet
    package.loaded["minuet.config"] = {}
    package.loaded["minuet.virtualtext"] = virtualtext
    package.loaded["minuet.backends.openai_fim_compatible"] = backend
    package.loaded["minuet.backends.common"] = { terminate_all_jobs = function() end }
    vim.cmd.packadd = function(name)
        equal(name, "minuet-ai.nvim")
        loads = loads + 1
    end
    local settings = {
        review_model = "qwen2.5-coder:3b",
        completion_model = "qwen2.5-coder:3b",
        choices = { ["qwen2.5-coder:3b"] = {} },
    }
    assert(not plugins.set_model({}))
    assert(not plugins.completion("unknown", settings))
    in_insert(function()
        assert(plugins.completion("next", settings))
    end)
    equal(setups, 1)
    equal(loads, 1)
    equal(minuet.config.virtualtext.auto_trigger_ft, {})
    equal(minuet.config.virtualtext.keymap, {})
    equal(minuet.config.cmp.enable_auto_complete, false)
    equal(minuet.config.lsp.completion.enable, false)
    equal(minuet.config.duet.auto_trigger.auto_trigger_ft, {})
    equal(vim.fn.maparg("<Tab>", "i", false, true), tab_before)
    for _, change in ipairs({ "edit", "switch", "cursor", "cancel", "disable" }) do
        normal()
        local buf = buffer("guard-" .. change .. ".lua")
        in_insert(function()
            assert(plugins.completion("next", settings))
            local callback = callbacks[#callbacks]
            if change == "edit" then
                api.nvim_buf_set_lines(buf, 0, 1, false, { "new edit" })
            elseif change == "switch" then
                api.nvim_set_current_buf(api.nvim_create_buf(true, false))
            elseif change == "cursor" then
                api.nvim_win_set_cursor(0, { 2, 0 })
            elseif change == "disable" then
                vim.b[buf].disable_local_ai = true
            else
                plugins.cancel()
            end
            local previous = received
            callback({ "stale suggestion" })
            equal(received, previous, change .. " must drop a stale completion")
            plugins.cancel()
        end)
    end
    normal()
    local buf = buffer("accept-completion.lua")
    in_insert(function()
        assert(plugins.completion("next", settings))
        callbacks[#callbacks]({ "fresh suggestion" })
        assert(visible)
        local schedule = vim.schedule
        assert(plugins.completion("accept", settings))
        equal(vim.schedule, schedule, "Accept must immediately restore the scheduler")
        api.nvim_buf_set_lines(buf, 0, 1, false, { "user intervened" })
        turn()
        equal(lines(buf)[1], "user intervened")
        assert(plugins.completion("next", settings))
        callbacks[#callbacks]({ "fresh suggestion" })
        assert(plugins.completion("accept_line", settings))
        turn()
        equal(lines(buf)[1], "accepted completion")
    end)
    assert(dismissed > 0)
    normal()
    plugins.cancel()
    equal(network, 0)
end)

-- Restore APIs before deleting buffers: teardown can call LSP and plugin hooks.
normal()
pcall(ai.reject)
pcall(ai.cancel)
vim.notify = saved.notify
vim.system = saved.system
vim.cmd.packadd = saved.packadd
vim.treesitter.get_node = saved.get_node
vim.lsp.get_clients = saved.get_clients
vim.ui.select = saved.select
vim.schedule = saved.schedule
for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(buf) then
        pcall(api.nvim_buf_delete, buf, { force = true })
    end
end
assert(vim.fn.delete(root, "rf") == 0, "Could not dispose temporary AI fixtures")
assert(vim.uv.fs_stat(root) == nil, "Temporary AI fixtures remain after cleanup")
equal(vim.lsp.get_clients, saved.get_clients, "LSP client API must remain restored before teardown")
print(string.format("AI config: %d passed, %d failed; %d real network/process calls", passed, #failures, network))
if #failures > 0 then
    vim.cmd("cquit 1")
end
