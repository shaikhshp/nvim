local M = {}
local python = require("user.python")

local function warn(message)
    vim.notify("Notebook: " .. message, vim.log.levels.WARN)
end

vim.g.molten_image_provider = "none"
vim.g.molten_auto_image_popup = false
vim.g.molten_auto_open_html_in_browser = false
vim.g.molten_auto_init_behavior = "raise"
vim.g.molten_auto_open_output = false
vim.g.molten_virt_text_output = true

local available, jupytext = pcall(require, "jupytext")
if not available then
    warn("Install goerz/jupytext.nvim with Lazy, then restart Neovim.")
elseif vim.fn.executable(python.jupytext) ~= 1 then
    warn(
        "Missing "
            .. python.jupytext
            .. "; install jupytext in the provider environment, then restart Neovim. .ipynb files will remain raw JSON until then."
    )
else
    -- The plugin's limited YAML parser crashes on list-valued notebook metadata.
    -- Use Jupytext's existing PyYAML dependency instead of rewriting the header.
    jupytext.parse_yaml = function(lines)
        local result = vim.system({
            python.host,
            "-c",
            "import json, sys, yaml; print(json.dumps(yaml.safe_load(sys.stdin.read()) or {}))",
        }, { text = true, stdin = table.concat(lines, "\n") }):wait(2000)
        if result.code ~= 0 then
            error("Unable to parse notebook metadata: " .. (result.stderr or "Python provider failed"))
        end
        return vim.json.decode(result.stdout)
    end
    local ok, err = pcall(jupytext.setup, {
        jupytext = python.jupytext,
        format = "py:percent",
        filetype = "python",
        update = true,
        autosync = true,
        -- Avoid clearing 'modified' for edits made during an older async save.
        async_write = false,
    })
    if not ok then
        warn("Jupytext setup failed: " .. tostring(err))
    end
end

local function output_maps(buffer)
    for _, key in ipairs({ "q", "<Esc>" }) do
        vim.keymap.set("n", key, function()
            M.run("MoltenHideOutput")
        end, {
            buffer = buffer,
            silent = true,
            desc = "Close notebook output",
        })
    end
end

function M.run(command)
    if vim.fn.executable(python.host) ~= 1 then
        warn(
            "Missing Python provider "
                .. python.host
                .. "; create its environment and install pynvim and jupyter_client, then run :UpdateRemotePlugins and restart Neovim."
        )
        return
    end
    local name = command:match("Molten%w+")
    if vim.fn.exists(":" .. name) ~= 2 then
        warn(
            "Missing :"
                .. name
                .. "; install benlubas/molten-nvim and the provider dependencies, run :UpdateRemotePlugins, then restart Neovim."
        )
        return
    end
    local ok, err = pcall(vim.cmd, command)
    if not ok then
        warn(tostring(err) .. " Initialize explicitly with <Space>mi / :MoltenInit before evaluating code.")
    elseif command == "noautocmd MoltenEnterOutput" then
        -- noautocmd also suppresses FileType when Molten creates the output.
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buffer = vim.api.nvim_win_get_buf(win)
            if vim.bo[buffer].filetype == "molten_output" then
                output_maps(buffer)
            end
        end
    end
end

function M.hide_output()
    -- Completed cells do not refresh their float on a source-side hide.
    -- Let Molten close it from the output context, keeping plugin state valid.
    local source = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local config = vim.api.nvim_win_get_config(win)
        local buffer = vim.api.nvim_win_get_buf(win)
        if config.relative == "win" and config.win == source and vim.bo[buffer].filetype == "molten_output" then
            vim.cmd("noautocmd call nvim_set_current_win(" .. win .. ")")
            break
        end
    end
    M.run("MoltenHideOutput")
end

function M.enable(buffer)
    buffer = buffer or vim.api.nvim_get_current_buf()
    if vim.bo[buffer].buftype ~= "" then
        warn(":NotebookEnable requires a normal file buffer.")
        return
    end
    vim.b[buffer].notebook_enabled = true
    local mappings = {
        { "mi", "MoltenInit", "Initialize notebook kernel" },
        { "me", "MoltenEvaluateOperator", "Evaluate notebook motion" },
        { "ml", "MoltenEvaluateLine", "Evaluate notebook line" },
        { "mc", "MoltenReevaluateCell", "Reevaluate Molten cell" },
        { "mo", "noautocmd MoltenEnterOutput", "Show/enter notebook output" },
        { "mq", "MoltenHideOutput", "Hide notebook output" },
        { "md", "MoltenDelete", "Delete Molten cell" },
        { "mx", "MoltenInterrupt", "Interrupt notebook kernel" },
    }
    for _, mapping in ipairs(mappings) do
        local command = mapping[2]
        vim.keymap.set("n", "<Space>" .. mapping[1], function()
            if command == "MoltenHideOutput" then
                M.hide_output()
            else
                M.run(command)
            end
        end, { buffer = buffer, silent = true, desc = mapping[3] })
    end
    -- Clear the visual range: MoltenEvaluateVisual does not accept one.
    vim.keymap.set(
        "x",
        "<Space>mv",
        ":<C-u>lua require(\"user.notebook\").run(\"MoltenEvaluateVisual\")<CR>gv",
        { buffer = buffer, silent = true, desc = "Evaluate notebook selection" }
    )
end

vim.api.nvim_create_user_command("NotebookEnable", function()
    M.enable()
end, { desc = "Opt this script into buffer-local notebook mappings", force = true })

local group = vim.api.nvim_create_augroup("UserNotebook", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "molten_output",
    callback = function(event)
        output_maps(event.buf)
    end,
})
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufFilePost" }, {
    group = group,
    pattern = "*.ipynb",
    callback = function(args)
        M.enable(args.buf)
    end,
    desc = "Attach notebook mappings without starting a kernel",
})

return M
