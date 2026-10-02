local M = { max_bytes = 128 * 1024, budget = 12000, extra_files = {} }

local function allowed_path(path)
    local name = vim.fs.basename(path):lower()
    local lower = path:lower():gsub("\\", "/")
    if
        name:match("^%.env")
        or name:match("%.env$")
        or name:match("%.pem$")
        or name:match("%.key$")
        or name:match("%.p12$")
        or name:match("%.pfx$")
        or name:match("%.ipynb$")
        or name:match("%.lock$")
        or name:match("%.tfstate")
        or name:match("^credentials")
        or name:match("^secrets%.")
        or name == ".netrc"
        or name == ".npmrc"
        or name == ".pypirc"
        or name == ".git-credentials"
        or name:match("^id_[a-z0-9]+$")
        or lower:find("/%.ssh/")
        or lower:find("/%.aws/")
        or lower:find("/%.gnupg/")
        or lower:find("/node_modules/")
        or lower:find("/target/")
        or lower:find("/dist/")
        or lower:find("/vendor/")
        or lower:find("/%.git/")
    then
        return false
    end
    return true
end

local function real_path(path)
    local suffix = {}
    local resolved = vim.uv.fs_realpath(path)
    while not resolved do
        local parent = vim.fs.dirname(path)
        if not parent or parent == path then return path end
        table.insert(suffix, 1, vim.fs.basename(path))
        path = parent
        resolved = vim.uv.fs_realpath(path)
    end
    return #suffix > 0 and vim.fs.joinpath(resolved, unpack(suffix)) or resolved
end

function M.eligible(buf)
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
        return false, "Buffer is unavailable"
    end
    local opts = vim.bo[buf]
    if opts.buftype ~= "" or not opts.modifiable or opts.readonly then
        return false, "Local AI requires a normal, writable file buffer"
    end
    local path = vim.api.nvim_buf_get_name(buf)
    if path == "" then
        return false, "Name the file before requesting local AI"
    end
    if not allowed_path(path) or not allowed_path(real_path(path)) then
        return false, "Local AI excludes secret, generated, dependency, and notebook files"
    end
    if vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf)) > M.max_bytes then
        return false, "Buffer exceeds the local AI size limit (128 KiB)"
    end
    if vim.b[buf].disable_local_ai then
        return false, "Local AI is disabled for this buffer"
    end
    return true
end

function M.snapshot(scope)
    local buf = vim.api.nvim_get_current_buf()
    local ok, reason = M.eligible(buf)
    if not ok then
        return nil, reason
    end
    local all = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local first, last = 1, #all
    if scope == "selection" then
        local mode = vim.fn.mode()
        if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
            return nil, "Select the code to review first"
        end
        first, last = vim.fn.getpos("v")[2], row
        if first > last then
            first, last = last, first
        end
    elseif scope ~= "buffer" then
        first, last = math.max(1, row - 20), math.min(#all, row + 20)
        local parsed, node = pcall(vim.treesitter.get_node, { bufnr = buf })
        while parsed and node do
            local kind = node:type()
            if kind:find("function") or kind:find("method") then
                local start_row, _, end_row, end_col = node:range()
                first, last = start_row + 1, end_row + (end_col > 0 and 1 or 0)
                break
            end
            node = node:parent()
        end
    end
    local path = vim.api.nvim_buf_get_name(buf)
    local snapshot = {
        buf = buf,
        tick = vim.api.nvim_buf_get_changedtick(buf),
        path = path,
        win = vim.api.nvim_get_current_win(),
        first = first,
        last = last,
        all = all,
        filetype = vim.bo[buf].filetype,
        root = vim.fs.root(buf, { ".git", "Cargo.toml", "pyproject.toml", "pom.xml", "package.json" })
            or vim.fs.dirname(path),
        lines = {},
        diagnostics = {},
    }
    snapshot.root = vim.uv.fs_realpath(snapshot.root) or snapshot.root
    for line = first, last do
        snapshot.lines[#snapshot.lines + 1] = all[line]
    end
    for _, diagnostic in ipairs(vim.diagnostic.get(buf)) do
        if diagnostic.source ~= "Ollama Review" and diagnostic.lnum >= first - 1 and diagnostic.lnum < last then
            snapshot.diagnostics[#snapshot.diagnostics + 1] = {
                line = diagnostic.lnum + 1,
                message = diagnostic.message,
                source = diagnostic.source,
                severity = diagnostic.severity,
            }
        end
    end
    return snapshot
end

function M.current(snapshot)
    local allowed = M.eligible(snapshot.buf)
    return allowed
        and vim.api.nvim_buf_get_name(snapshot.buf) == snapshot.path
        and vim.api.nvim_buf_get_changedtick(snapshot.buf) == snapshot.tick
        and vim.deep_equal(vim.api.nvim_buf_get_lines(snapshot.buf, 0, -1, false), snapshot.all)
end

function M.render(snapshot)
    local lines = {
        "File: " .. vim.fs.basename(snapshot.path),
        "Language: " .. snapshot.filetype,
        "Source lines " .. snapshot.first .. "-" .. snapshot.last .. " (absolute one-based line numbers):",
        "<source>",
    }
    for i, text in ipairs(snapshot.lines) do
        lines[#lines + 1] = (snapshot.first + i - 1) .. " | " .. text
    end
    lines[#lines + 1] = "</source>"
    if snapshot.first > 1 then
        local header = {}
        for i = 1, math.min(snapshot.first - 1, 15) do
            header[#header + 1] = snapshot.all[i]
        end
        local text = table.concat(header, "\n")
        if #text <= 2000 then
            lines[#lines + 1] = "File header (context only; not part of the replacement):\n<header>\n"
                .. text
                .. "\n</header>"
        end
    end
    lines[#lines + 1] = "Existing compiler/linter diagnostics: " .. vim.json.encode(snapshot.diagnostics)
    for _, extra in ipairs(M.extra_files) do
        if extra.root == snapshot.root then
            lines[#lines + 1] = "Explicit context file: "
                .. extra.path
                .. "\n<additional-source>\n"
                .. extra.text
                .. "\n</additional-source>"
        end
    end
    local text = table.concat(lines, "\n")
    if #text > M.budget then
        return nil, "Context exceeds 12,000 bytes; select a smaller region or clear extra context"
    end
    return text
end

function M.add_file(path)
    local snapshot, err = M.snapshot("function")
    if not snapshot then
        return false, err
    end
    local root = vim.uv.fs_realpath(snapshot.root) or snapshot.root
    if not allowed_path(vim.fs.joinpath(root, path)) then
        return false, "Secret, generated, dependency, and notebook context is excluded"
    end
    path = vim.uv.fs_realpath(vim.fs.joinpath(root, path))
    if not path or path:sub(1, #root + 1) ~= root .. "/" then
        return false, "Context files must resolve inside this project root"
    end
    local stat = vim.uv.fs_stat(path)
    if not stat or stat.type ~= "file" or stat.size > 4000 then
        return false, "Additional context must be a file of at most 4,000 bytes"
    end
    if not allowed_path(path) then
        return false, "Secret, generated, dependency, and notebook context is excluded"
    end
    local text
    local buf = vim.fn.bufnr(path)
    if buf > 0 and vim.api.nvim_buf_is_loaded(buf) then
        local ok, reason = M.eligible(buf)
        if not ok then
            return false, reason
        end
        text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    else
        local ok, lines = pcall(vim.fn.readfile, path)
        if not ok then
            return false, "Could not read the requested context file"
        end
        text = table.concat(lines, "\n")
    end
    if #text > 4000 then
        return false, "Additional context exceeds 4,000 bytes"
    end
    for _, extra in ipairs(M.extra_files) do
        if extra.absolute == path then
            return false, "This context file is already attached"
        end
    end
    if #M.extra_files >= 3 then
        return false, "Clear context before attaching more than three files"
    end
    M.extra_files[#M.extra_files + 1] = {
        root = snapshot.root,
        path = path:sub(#root + 2),
        absolute = path,
        text = text,
    }
    return true
end

return M
