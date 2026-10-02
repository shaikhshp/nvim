local ok, project = pcall(require, "project_nvim")
if not ok then
    return
end
project.setup({
    manual_mode = false,
    detection_methods = { "pattern" },
    patterns = {
        ".git",
        "_darcs",
        ".hg",
        ".bzr",
        ".svn",
        "Makefile",
        "package.json",
        "Cargo.toml",
        "pyproject.toml",
        "pom.xml",
        "settings.gradle",
        "settings.gradle.kts",
    },
    show_hidden = false,
    silent_chdir = true,
    datapath = vim.fn.stdpath("data"),
})

local telescope_ok, telescope = pcall(require, "telescope")
if not telescope_ok then
    return
end
telescope.load_extension("projects")
local projects = telescope.extensions.projects.projects
telescope.extensions.projects.projects = function(opts)
    opts = vim.tbl_extend("force", {}, opts or {})
    local attach = opts.attach_mappings
    opts.attach_mappings = function(prompt, map)
        -- The pinned project extension calls Telescope's removed file_browser.
        -- Browse with the already-configured tree instead.
        local function browse()
            local entry = require("telescope.actions.state").get_selected_entry()
            require("telescope.actions").close(prompt)
            if entry then
                require("project_nvim.project").set_pwd(entry.value, "telescope")
                require("nvim-tree").open(entry.value)
            end
        end
        map("n", "b", browse)
        map("i", "<C-b>", browse)
        if attach then
            return attach(prompt, map)
        end
        return true
    end
    return projects(opts)
end
