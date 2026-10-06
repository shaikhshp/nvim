-- Run: nvim --headless -u NONE -i NONE -l tests/ui_config.lua
vim.opt.runtimepath:append(vim.fn.getcwd())
local root = vim.fn.getcwd()
local passed, process_calls, writes = 0, 0, 0
local function check(condition, message)
    assert(condition, message)
    passed = passed + 1
end
local function equal(actual, expected, message)
    check(vim.deep_equal(actual, expected), message .. ": " .. vim.inspect(actual))
end

local saved_packages = {}
local function stub(name, loader)
    if not saved_packages[name] then
        saved_packages[name] = { loaded = package.loaded[name], preload = package.preload[name] }
    end
    -- A failed LuaJIT require leaves a sentinel; clear it explicitly before retrying.
    package.loaded[name] = nil
    package.preload[name] = loader
end
local function missing(name)
    stub(name, function()
        error("fixture missing dependency: " .. name)
    end)
end
local function load(name)
    return dofile(root .. "/lua/user/" .. name .. ".lua")
end
local notices, notify = {}, vim.notify
vim.notify = function(message)
    notices[#notices + 1] = message
end
local blocked = {}
local function block(owner, key)
    blocked[#blocked + 1] = { owner, key, owner[key] }
    owner[key] = function()
        process_calls = process_calls + 1
        error("Unexpected process call: " .. key)
    end
end
block(vim, "system")
for _, key in ipairs({ "system", "systemlist", "jobstart", "jobwait" }) do
    block(vim.fn, key)
end
vim.api.nvim_create_autocmd({ "BufWritePre", "BufWritePost", "FileWritePre", "FileWritePost" }, {
    callback = function()
        writes = writes + 1
    end,
})

load("keymaps")
local function mapping(key, mode)
    return vim.fn.maparg(" " .. key, mode or "n", false, true)
end
local function invoke(key)
    local map = mapping(key)
    check(type(map.callback) == "function", "callback for " .. key)
    map.callback()
end
local baseline = vim.api.nvim_get_keymap("n")
for index, map in ipairs(baseline) do
    baseline[index] = vim.fn.maparg(map.lhs, "n", false, true)
end
for key, rhs in pairs({
    a = "<cmd>Alpha<CR>",
    u = "<cmd>redo<CR>",
    gd = "<cmd>Gitsigns diffthis HEAD<CR>",
    pc = "<cmd>Lazy check<CR>",
    pi = "<cmd>lua require('lazy').install({ lockfile = true })<CR>",
    ps = "<cmd>Lazy sync<CR>",
    pS = "<cmd>Lazy<CR>",
    pu = "<cmd>Lazy update<CR>",
}) do
    equal(mapping(key).rhs, rhs, "existing/manager mapping before feature setup: " .. key)
end
check(type(mapping("e").callback) == "function", "existing explorer callback")
check(mapping("lq").callback == vim.diagnostic.setloclist, "existing diagnostic location list")

missing("aerial")
missing("diffview")
check(pcall(load, "aerial"), "Aerial missing-plugin guard")
check(pcall(load, "diffview"), "Diffview missing-plugin guard")
check(next(mapping("gD")) == nil, "missing Diffview registers no keys")
local aerial_options
stub("aerial", function()
    return {
        setup = function(opts)
            aerial_options = opts
        end,
    }
end)
local fold_options = {}
for _, key in ipairs({ "foldmethod", "foldexpr", "foldenable", "foldlevel" }) do
    fold_options[key] = vim.wo[key]
end
load("aerial")
equal(aerial_options.attach_mode, "global", "Aerial global attachment")
equal(aerial_options.open_automatic, false, "Aerial opens explicitly")
for _, key in ipairs({ "manage_folds", "link_folds_to_tree", "link_tree_to_folds" }) do
    equal(aerial_options[key], false, "Aerial fold ownership: " .. key)
end
for key, value in pairs(fold_options) do
    equal(vim.wo[key], value, "source fold option untouched: " .. key)
end
equal(aerial_options.ignore.buftypes, "special", "Aerial skips special buffers")
equal(aerial_options.ignore.wintypes, "special", "Aerial skips special windows")
equal(aerial_options.ignore.diff_windows, true, "Aerial skips diff windows")
for _, ft in ipairs({ "NvimTree", "alpha", "undotree", "DiffviewFiles", "DiffviewFileHistory" }) do
    check(vim.tbl_contains(aerial_options.ignore.filetypes, ft), "Aerial excludes " .. ft)
end
equal(aerial_options.keymaps, { ["<C-j>"] = false, ["<C-k>"] = false }, "Aerial preserves window navigation")

local source = vim.api.nvim_get_current_win()
local buffer = vim.api.nvim_win_get_buf(source)
vim.api.nvim_buf_set_name(buffer, root .. "/fixture source with spaces.lua")
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "local fixture = true" })
local source_name = vim.api.nvim_buf_get_name(buffer)
local source_tick = vim.api.nvim_buf_get_changedtick(buffer)
local selected = source
stub("user.sidebar", function()
    return {
        source_window = function()
            return selected
        end,
    }
end)
local diff_options, calls, closes = nil, {}, 0
local current_view
stub("diffview.lib", function()
    return {
        get_current_view = function()
            return current_view
        end,
    }
end)
stub("diffview", function()
    return {
        setup = function(opts)
            diff_options = opts
        end,
        open = function(args)
            calls[#calls + 1] = { kind = "open", args = args }
        end,
        file_history = function(range, args)
            check(range == nil, "history uses supported nil range")
            calls[#calls + 1] = { kind = "history", args = args }
        end,
        close = function()
            closes = closes + 1
        end,
    }
end)
local actions, allowed_actions = {}, {}
for _, name in ipairs({
    "select_next_entry",
    "select_prev_entry",
    "goto_file_edit",
    "goto_file_tab",
    "focus_files",
    "toggle_files",
    "cycle_layout",
    "next_entry",
    "prev_entry",
    "select_entry",
    "toggle_fold",
    "refresh_files",
    "copy_hash",
    "open_commit_log",
    "options",
    "close",
}) do
    actions[name] = function() end
    allowed_actions[actions[name]] = true
end
actions.help = function(panel)
    check(vim.tbl_contains({ "view", "file_panel", "file_history_panel", "option_panel" }, panel), "help panel")
    local callback = function() end
    allowed_actions[callback] = true
    return callback
end
stub("diffview.actions", function()
    return actions
end)
load("diffview")
equal(diff_options.keymaps.disable_defaults, true, "Diffview disables default controls")
for panel, maps in pairs(diff_options.keymaps) do
    if type(maps) == "table" then
        for _, map in ipairs(maps) do
            check(map[1] == "n" and allowed_actions[map[3]], "review-only Normal action in " .. panel)
        end
    end
end
equal(diff_options.view.default, { layout = "diff2_horizontal", disable_diagnostics = false }, "review layout")
equal(diff_options.view.file_history, diff_options.view.default, "history layout")
local tab = vim.api.nvim_get_current_tabpage()
local function view_fixture(tabpage)
    local handlers = {}
    local view = {
        tabpage = tabpage,
        emitter = {
            on = function(_, event, callback)
                handlers[event] = callback
            end,
        },
    }
    return view, handlers
end
local hook_view, hook_handlers = view_fixture(tab)
diff_options.hooks.view_opened(hook_view)
check(vim.t.user_diffview == true, "view_opened sets tab review marker")
check(type(hook_handlers.file_open_pre) == "function", "view subscribes to file-open pre")
check(type(hook_handlers.file_open_post) == "function", "view subscribes to file-open post")
diff_options.hooks.view_closed(hook_view)
check(vim.t.user_diffview == false, "view_closed clears tab review marker")
for _, fixture in ipairs({ (view_fixture(nil)), (view_fixture(999999)) }) do
    check(pcall(diff_options.hooks.view_opened, fixture), "open hook tolerates absent/invalid tab")
    check(pcall(diff_options.hooks.view_closed, fixture), "close hook tolerates absent/invalid tab")
end
for _, case in ipairs({
    { "gD", "open", { "HEAD", "--", ":(exclude,glob)**/*.ipynb" } },
    { "gF", "open", { "HEAD", "--", source_name } },
    { "gh", "history", { source_name } },
    { "gH", "history", {} },
}) do
    invoke(case[1])
    equal(calls[#calls], { kind = case[2], args = case[3] }, "supported API args: " .. case[1])
end
invoke("gQ")
equal(closes, 1, "close review API")
for _, case in ipairs({
    { "loading-not-ready", { ready = false } },
    { "panel-updating", { ready = true, panel = { updating = true } } },
    { "entry-not-opened", { ready = true, panel = { updating = false }, cur_entry = { opened = false } } },
    {
        "files-loading",
        {
            ready = true,
            panel = { updating = false },
            cur_entry = { opened = true },
            cur_layout = {
                is_files_loaded = function()
                    return false
                end,
            },
        },
    },
}) do
    current_view = case[2]
    local count, notice_count = closes, #notices
    invoke("gQ")
    equal(closes, count, "close deferred: " .. case[1])
    equal(#notices, notice_count + 1, "close guidance emitted: " .. case[1])
    equal(
        notices[#notices],
        "Diffview is still opening revision content; retry close when loaded",
        "close retry guidance: " .. case[1]
    )
end
current_view = {
    ready = true,
    panel = { updating = false },
    cur_entry = { opened = true },
    cur_layout = {
        is_files_loaded = function()
            return true
        end,
    },
}
local notice_count = #notices
invoke("gQ")
equal(closes, 2, "completed entry permits close")
equal(#notices, notice_count, "completed entry needs no retry guidance")
current_view = { ready = true, panel = { updating = false } }
invoke("gQ")
equal(closes, 3, "empty ready view permits close without entry or layout")
equal(#notices, notice_count, "empty ready view needs no retry guidance")
local lifecycle_view, lifecycle_handlers = view_fixture(tab)
lifecycle_view.ready = true
lifecycle_view.panel = { updating = false }
lifecycle_view.cur_entry = { opened = true }
lifecycle_view.cur_layout = {
    is_files_loaded = function()
        return true
    end,
}
diff_options.hooks.view_opened(lifecycle_view)
current_view = lifecycle_view
local close_count = closes
for _, label in ipairs({ "cached opened entry reopening", "overlapping opens after post A" }) do
    lifecycle_handlers.file_open_pre() -- A
    if label == "overlapping opens after post A" then
        lifecycle_handlers.file_open_pre() -- B
        lifecycle_handlers.file_open_post() -- A completes; B is still opening.
    end
    local count = #notices
    invoke("gQ")
    equal(closes, close_count, "active opening blocks close: " .. label)
    equal(#notices, count + 1, "active opening emits guidance: " .. label)
    equal(
        notices[#notices],
        "Diffview is still opening revision content; retry close when loaded",
        "active opening guidance"
    )
    lifecycle_handlers.file_open_post()
    invoke("gQ")
    close_count = close_count + 1
    equal(closes, close_count, "all opens completed permits close: " .. label)
end
lifecycle_handlers.file_open_pre()
diff_options.hooks.view_closed(lifecycle_view)
invoke("gQ")
equal(closes, close_count + 1, "view_closed clears active opening count")
current_view = nil
local notebook_name = root .. "/fixture notebook with spaces.ipynb"
vim.api.nvim_buf_set_name(buffer, notebook_name)
local call_count, notebook_notices = #calls, #notices
invoke("gF")
equal(#calls, call_count, "working-tree notebook review rejected")
equal(#notices, notebook_notices + 1, "notebook rejection emits guidance")
equal(
    notices[#notices],
    "Notebook buffers display Python, not Git JSON; use history or a notebook-aware diff tool",
    "notebook guidance"
)
invoke("gh")
equal(calls[#calls], { kind = "history", args = { notebook_name } }, "notebook file history permits Git JSON")
invoke("gH")
equal(calls[#calls], { kind = "history", args = {} }, "notebook project history has no exclusions")
invoke("gD")
equal(
    calls[#calls],
    { kind = "open", args = { "HEAD", "--", ":(exclude,glob)**/*.ipynb" } },
    "notebook source project review excludes notebooks"
)
vim.api.nvim_buf_set_name(buffer, source_name)
selected = nil
invoke("gD")
equal(
    calls[#calls],
    { kind = "open", args = { "-C" .. root, "HEAD", "--", ":(exclude,glob)**/*.ipynb" } },
    "project review without source uses cwd and excludes notebooks"
)
invoke("gH")
equal(calls[#calls], { kind = "history", args = { "-C" .. root } }, "project history without source uses cwd")

local undo = load("undotree")
undo.init()
for key, value in pairs({
    CustomUndotreeCmd = "botright 12new",
    CustomDiffpanelCmd = "belowright vertical 60new",
    SetFocusWhenToggle = 1,
    DiffAutoOpen = 0,
    ShortIndicators = 1,
    HighlightChangedWithSign = 0,
}) do
    equal(vim.g["undotree_" .. key], value, "Undotree init: " .. key)
end
undo.setup()
invoke("Ut")
check(notices[#notices]:find("not installed", 1, true) ~= nil, "Undotree missing-command guard")
local undo_calls = {}
for _, command in ipairs({ "UndotreeToggle", "UndotreeShow" }) do
    vim.api.nvim_create_user_command(command, function()
        undo_calls[#undo_calls + 1] = { command, vim.api.nvim_get_current_win() }
    end, {})
end

local function rejects(label)
    local count, undo_count = #calls, #undo_calls
    invoke("gF")
    invoke("gh")
    invoke("Ut")
    invoke("Uf")
    equal(#calls, count, "current-file review rejects " .. label)
    equal(#undo_calls, undo_count, "Undotree rejects " .. label)
end
rejects("missing source")
selected = 999999
rejects("invalid window")
selected = source
vim.wo[source].diff = true
rejects("diff source")
vim.wo[source].diff = false
vim.bo[buffer].buftype = "nofile"
rejects("special buffer")
vim.bo[buffer].buftype = ""
for _, name in ipairs({ "", "fixture://revision/path", root }) do
    vim.api.nvim_buf_set_name(buffer, name)
    rejects("filename " .. name)
end
vim.api.nvim_buf_set_name(buffer, source_name)
local floating = vim.api.nvim_open_win(buffer, false, {
    relative = "editor",
    row = 1,
    col = 1,
    width = 15,
    height = 3,
})
selected = floating
rejects("floating window")
vim.api.nvim_win_close(floating, true)
vim.cmd("tabnew")
local other_tab, other_source = vim.api.nvim_get_current_tabpage(), vim.api.nvim_get_current_win()
vim.api.nvim_set_current_tabpage(tab)
selected = other_source
rejects("other tab source")
selected = source
for _, option in ipairs({ "readonly", "modifiable" }) do
    local old = vim.bo[buffer][option]
    vim.bo[buffer][option] = option == "readonly"
    local count = #undo_calls
    invoke("Uf")
    equal(#undo_calls, count, "Undotree rejects " .. option)
    vim.bo[buffer][option] = old
end
invoke("Ut")
invoke("Uf")
equal(undo_calls, { { "UndotreeToggle", source }, { "UndotreeShow", source } }, "Undotree commands run in source")
for _, map in ipairs(baseline) do
    local current = vim.fn.maparg(map.lhs, "n", false, true)
    check(
        current.rhs == map.rhs and current.callback == map.callback and current.desc == map.desc,
        "existing mapping preserved: " .. map.lhs
    )
end
for _, key in ipairs({ "ot", "of", "on", "op", "gD", "gF", "gh", "gH", "gQ", "Ut", "Uf" }) do
    check(mapping(key).buffer == 0 and type(mapping(key).callback) == "function", "global Normal key: " .. key)
    for _, mode in ipairs({ "i", "x", "o" }) do
        check(next(mapping(key, mode)) == nil, "no " .. mode .. " mapping for " .. key)
    end
end

-- Reload the actual coordinator after the Diffview/Undotree source-helper stub.
local sidebar = load("sidebar")
stub("user.sidebar", function()
    return sidebar
end)
local events, tree_toggles = {}, 0
stub("nvim-tree.api", function()
    return {
        tree = {
            toggle = function()
                tree_toggles = tree_toggles + 1
            end,
        },
        events = {
            Event = { TreeOpen = "open", TreeClose = "close" },
            subscribe = function(event, callback)
                events[event] = callback
            end,
        },
    }
end)
sidebar.setup()
equal(sidebar.source_window(), source, "normal source selected")
check(type(events.open) == "function" and type(events.close) == "function", "fake tree events subscribed")
events.open()
events.close()
vim.wait(20, function()
    return false
end)
local utility_buf = vim.api.nvim_create_buf(false, true)
vim.cmd("vsplit")
local utility = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_buf(utility, utility_buf)
vim.bo[utility_buf].buftype = ""
for _, ft in ipairs({ "NvimTree", "aerial", "alpha", "undotree", "DiffviewFiles", "DiffviewFileHistory" }) do
    vim.bo[utility_buf].filetype = ft
    equal(sidebar.source_window(), source, "last source retained from " .. ft)
end
vim.bo[utility_buf].filetype = ""
vim.bo[utility_buf].buftype = "nofile"
equal(sidebar.source_window(), source, "special buftype excluded")
floating = vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    row = 1,
    col = 1,
    width = 15,
    height = 3,
})
equal(sidebar.source_window(), source, "floating window excluded")
vim.api.nvim_win_close(floating, true)
vim.api.nvim_set_current_win(utility)
vim.wo[source].diff = true
equal(sidebar.source_window(), nil, "no eligible source when last source becomes diff")
vim.wo[source].diff = false
equal(sidebar.source_window(), source, "valid source recovered")
vim.t.user_diffview = true
equal(sidebar.source_window(), nil, "review tab excludes sources")
sidebar.tree_toggle()
equal(tree_toggles, 0, "review tab tree toggle blocked")
vim.t.user_diffview = false
vim.api.nvim_set_current_tabpage(other_tab)
equal(sidebar.source_window(), other_source, "tab-local source selection")
vim.bo[vim.api.nvim_win_get_buf(other_source)].buftype = "nofile"
equal(sidebar.source_window(), nil, "never falls back to source in another tab")
vim.api.nvim_set_current_tabpage(tab)
equal(sidebar.source_window(), source, "first tab source retained")
vim.api.nvim_win_close(source, true)
equal(sidebar.source_window(), nil, "closed remembered source is rejected")
vim.api.nvim_win_set_buf(utility, buffer)
equal(sidebar.source_window(), utility, "replacement source recovered")
vim.api.nvim_exec_autocmds("User", { pattern = "PersistenceLoadPre" })
equal(sidebar.source_window(), nil, "session restore suspends source discovery")
vim.api.nvim_exec_autocmds("User", { pattern = "PersistenceLoadPost" })
equal(sidebar.source_window(), utility, "session restore resumes source discovery")
vim.wait(20, function()
    return false
end)

missing("nvim-tree.api")
check(pcall(sidebar.setup), "sidebar setup missing-tree guard")
check(pcall(sidebar.tree_toggle), "tree missing-plugin guard")
missing("aerial")
check(pcall(sidebar.outline_open, false), "outline missing-plugin guard")
check(pcall(sidebar.outline_move, true), "outline movement missing-plugin guard")
local opens, movements = {}, {}
stub("aerial", function()
    return {
        open = function(opts)
            opens[#opens + 1] = opts
        end,
        next = function()
            movements[#movements + 1] = "next"
        end,
        prev = function()
            movements[#movements + 1] = "prev"
        end,
    }
end)
-- The open stub records intent only; real panel geometry belongs to live tests.
sidebar.outline_open(false)
equal(opens, { { focus = false, direction = "left" } }, "explicit Aerial open hook")
equal(vim.api.nvim_get_current_win(), utility, "unfocused outline open retains source focus")
sidebar.outline_move(true)
sidebar.outline_move(false)
equal(movements, { "next", "prev" }, "Aerial movement hooks")
vim.t.user_diffview = true
sidebar.outline_open(false)
sidebar.outline_move(true)
equal(#opens, 1, "outline open blocked in review tab")
equal(#movements, 2, "outline movement blocked in review tab")
vim.t.user_diffview = false

-- Disable scheduling so these fixtures exercise the explicit close paths only.
vim.api.nvim_del_augroup_by_name("UserSidebar")
vim.api.nvim_win_close(other_source, true)
-- Earlier FileType fixtures set fixed dimensions; use normal-window defaults here.
local fixed_defaults = {}
for _, option in ipairs({ "winfixwidth", "winfixheight" }) do
    fixed_defaults[option] = vim.api.nvim_get_option_value(option, { scope = "global" })
    vim.api.nvim_set_option_value(option, false, { scope = "global" })
end
for _, action in ipairs({ "outline_toggle", "reconcile" }) do
    local outline = vim.api.nvim_get_current_win()
    local outline_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[outline_buf].filetype = "aerial"
    vim.api.nvim_win_set_buf(outline, outline_buf)
    local normal_options = {}
    for option, alternate in pairs({
        list = true,
        number = true,
        relativenumber = true,
        signcolumn = "no",
        foldcolumn = "1",
        wrap = false,
        spell = true,
        winfixwidth = true,
        winfixheight = true,
    }) do
        local global = vim.api.nvim_get_option_value(option, { scope = "global" })
        normal_options[option] = global
        if type(global) == "boolean" then
            alternate = not global
        elseif alternate == global then
            alternate = option == "signcolumn" and "yes" or "0"
        end
        vim.api.nvim_set_option_value(option, alternate, { win = outline, scope = "local" })
    end
    equal(#vim.api.nvim_list_tabpages(), 1, "last-outline fixture has one tab")
    equal(#vim.api.nvim_tabpage_list_wins(0), 1, "last-outline fixture has one window")
    local count = #notices
    sidebar[action]()
    check(not vim.api.nvim_win_is_valid(outline), "sole outline closed: " .. action)
    equal(#notices, count, "sole outline close has no error: " .. action)
    equal(#vim.api.nvim_tabpage_list_wins(0), 1, "one replacement window: " .. action)
    local replacement = vim.api.nvim_get_current_win()
    local replacement_buf = vim.api.nvim_win_get_buf(replacement)
    equal(vim.api.nvim_win_get_config(replacement).relative, "", "replacement is regular")
    equal(vim.bo[replacement_buf].buftype, "", "replacement is normal buffer")
    equal(vim.bo[replacement_buf].filetype, "", "replacement is not outline")
    equal(vim.api.nvim_buf_get_name(replacement_buf), "", "replacement is unnamed")
    equal(vim.api.nvim_buf_get_lines(replacement_buf, 0, -1, false), { "" }, "replacement is blank")
    check(
        vim.bo[replacement_buf].buflisted and not vim.bo[replacement_buf].modified,
        "replacement is listed and unmodified"
    )
    for option, global in pairs(normal_options) do
        equal(
            vim.api.nvim_get_option_value(option, { win = replacement }),
            global,
            "replacement restores global " .. option
        )
    end
    equal(sidebar.source_window(), replacement, "replacement is eligible source")
end
for option, value in pairs(fixed_defaults) do
    vim.api.nvim_set_option_value(option, value, { scope = "global" })
end

equal(vim.api.nvim_buf_get_changedtick(buffer), source_tick, "UI actions do not edit source")
equal(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), { "local fixture = true" }, "source text preserved")
equal(writes, 0, "no source writes")
equal(process_calls, 0, "no process/network calls")
vim.api.nvim_del_augroup_by_name("UserUndotree")
for name, saved in pairs(saved_packages) do
    package.loaded[name], package.preload[name] = saved.loaded, saved.preload
end
for _, saved in ipairs(blocked) do
    saved[1][saved[2]] = saved[3]
end
vim.notify = notify
print(string.format("PASS: %d UI assertions, 0 source writes, 0 process/network calls (stubbed plugins)", passed))
