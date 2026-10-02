return {
    before_init = function(_, config)
        config.settings.python.pythonPath = require("user.python").project_python(config.root_dir)
    end,
    settings = {
        pyright = { disableOrganizeImports = true },
        python = {
            analysis = {
                typeCheckingMode = "basic",
            },
        },
    },
}
