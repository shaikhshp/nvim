local M = {}

function M.setup()
    local ok, jdtls = pcall(require, "jdtls")
    if not ok then
        return
    end
    local command = vim.fn.exepath("jdtls")
    if command == "" then
        local mason = vim.fn.stdpath("data") .. "/mason/bin/jdtls"
        if vim.fn.executable(mason) ~= 1 then
            return
        end
        command = mason
    end
    local root = vim.fs.root(0, {
        { "gradlew", "mvnw", "settings.gradle", "settings.gradle.kts", ".git" },
        { "pom.xml", "build.gradle", "build.gradle.kts", "build.xml" },
    })
    if not root then
        return
    end
    root = vim.uv.fs_realpath(root) or root
    local workspace = vim.fn.stdpath("cache")
        .. "/jdtls/"
        .. vim.fn.fnamemodify(root, ":t")
        .. "-"
        .. vim.fn.sha256(root):sub(1, 16)
    local packages = vim.fn.stdpath("data") .. "/mason/packages/"
    local bundles = vim.fn.glob(
        packages .. "java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
        false,
        true
    )
    local has_debug = #bundles > 0
    local tests = vim.fn.glob(packages .. "java-test/extension/server/*.jar", false, true)
    for _, jar in ipairs(tests) do
        local name = vim.fn.fnamemodify(jar, ":t")
        -- JDTLS already loads these exact dependency bundles (notably ASM).
        if
            name ~= "com.microsoft.java.test.runner-jar-with-dependencies.jar"
            and name ~= "jacocoagent.jar"
            and vim.fn.filereadable(packages .. "jdtls/plugins/" .. name) == 0
        then
            bundles[#bundles + 1] = jar
        end
    end
    local handlers = require("user.lsp.handlers")
    local dap_ok = pcall(require, "dap")
    if dap_ok and has_debug then
        jdtls.setup_dap({ hotcodereplace = "auto" })
    end
    jdtls.start_or_attach({
        cmd = { command, "-data", workspace },
        root_dir = root,
        capabilities = handlers.capabilities,
        init_options = { bundles = bundles },
        settings = { java = { configuration = { updateBuildConfiguration = "interactive" } } },
        on_attach = function(client, bufnr)
            handlers.on_attach(client, bufnr)
            local function test(method)
                return function()
                    if not dap_ok or not has_debug or #tests == 0 then
                        vim.notify("Java tests require DAP, java-debug-adapter and java-test", vim.log.levels.WARN)
                        return
                    end
                    jdtls[method]()
                end
            end
            vim.keymap.set(
                "n",
                "<leader>jo",
                jdtls.organize_imports,
                { buffer = bufnr, silent = true, desc = "Java organize imports" }
            )
            vim.keymap.set(
                "n",
                "<leader>jt",
                test("test_nearest_method"),
                { buffer = bufnr, silent = true, desc = "Java debug nearest test" }
            )
            vim.keymap.set(
                "n",
                "<leader>jT",
                test("test_class"),
                { buffer = bufnr, silent = true, desc = "Java debug test class" }
            )
        end,
    })
end

return M
