local install_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local manager_commit = "85c7ff3711b730b4030d03144f6db6375044ae82"
if not vim.uv.fs_stat(install_path) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--no-checkout",
        "https://github.com/folke/lazy.nvim.git",
        install_path,
    })
    if vim.v.shell_error == 0 then
        vim.fn.system({ "git", "-C", install_path, "checkout", manager_commit })
    end
    if vim.v.shell_error ~= 0 then
        vim.notify("Unable to install Lazy: check Git and network access", vim.log.levels.ERROR)
        return
    end
end
vim.opt.runtimepath:prepend(install_path)

require("lazy").setup({
    { "folke/lazy.nvim", commit = manager_commit, pin = true },
    -- CodeCompanion needs Plenary's newer streaming/error callbacks.
    { "nvim-lua/plenary.nvim", commit = "74b06c6c75e4eeb3108ec01852001636d85a932b" },
    { "nvim-tree/nvim-web-devicons", commit = "563f3635c2d8a7be7933b9e547f7c178ba0d4352" },

    -- Appearance and navigation.
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
    { "folke/tokyonight.nvim", commit = "66bfc2e8f754869c7b651f3f47a2ee56ae557764" },
    { "lunarvim/darkplus.nvim", commit = "13ef9daad28d3cf6c5e793acfc16ddbf456e1c83" },
    { "rose-pine/neovim", name = "rose-pine" },
    { "Shatur/neovim-ayu" },
    { "nvim-tree/nvim-tree.lua", commit = "7282f7de8aedf861fe0162a559fc2b214383c51c" },
    { "akinsho/bufferline.nvim", tag = "v4.9.1", dependencies = "nvim-tree/nvim-web-devicons" },
    { "moll/vim-bbye", commit = "25ef93ac5a87526111f43e5110675032dbcacf56" },
    { "nvim-lualine/lualine.nvim", commit = "a52f078026b27694d2290e34efa61a6e4a690621" },
    { "lukas-reineke/indent-blankline.nvim", commit = "db7cbcb40cc00fc5d6074d7569fb37197705e7f6" },
    { "goolord/alpha-nvim" },
    { "folke/persistence.nvim", commit = "b20b2a7887bd39c1a356980b45e03250f3dce49c" },
    { "folke/which-key.nvim" },
    { "NvChad/nvim-colorizer.lua" },
    { "nvim-telescope/telescope.nvim", tag = "0.1.5", dependencies = "nvim-lua/plenary.nvim" },
    { "ahmedkhalf/project.nvim", commit = "628de7e433dd503e782831fe150bb750e56e55d6" },
    { "lewis6991/gitsigns.nvim", commit = "2c6f96dda47e55fa07052ce2e2141e8367cbaaf2" },
    { "akinsho/toggleterm.nvim", commit = "2a787c426ef00cb3488c11b14f5dcf892bbd0bda" },

    -- Editing and completion: native LSP is the only language-service stack.
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    { "windwp/nvim-ts-autotag" },
    { "windwp/nvim-autopairs", commit = "4fc96c8f3df89b6d23e5092d31c866c53a346347" },
    { "numToStr/Comment.nvim", commit = "97a188a98b5a3a6f9b1b850799ac078faa17ab67" },
    { "JoosepAlviste/nvim-ts-context-commentstring" },
    { "RRethy/vim-illuminate" },
    { "hrsh7th/nvim-cmp" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-nvim-lua" },
    { "saadparwaiz1/cmp_luasnip" },
    { "L3MON4D3/LuaSnip" },
    { "rafamadriz/friendly-snippets" },
    { "onsails/lspkind-nvim" },
    { "stevearc/conform.nvim" },

    -- Only the guarded AI wrapper may load these; even require() must not auto-load them.
    {
        "olimorris/codecompanion.nvim",
        tag = "v19.27.0",
        lazy = true,
        module = false,
        dependencies = "nvim-lua/plenary.nvim",
    },
    { "milanglacier/minuet-ai.nvim", commit = "3b0a4c5f97b7124d94302c608fbe01c0270d4fbe", lazy = true, module = false },

    -- Language services and debugging.
    { "neovim/nvim-lspconfig" },
    { "mason-org/mason.nvim" },
    { "mason-org/mason-lspconfig.nvim" },
    { "mfussenegger/nvim-jdtls", dependencies = "mfussenegger/nvim-dap" },
    { "mfussenegger/nvim-dap" },
    { "mfussenegger/nvim-dap-python" },
    { "nvim-neotest/nvim-nio", lazy = false },
    { "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },

    -- Documents, notebooks, and optional workflow tools.
    { "lervag/vimtex" },
    { "ellisonleao/glow.nvim" },
    {
        "iamcco/markdown-preview.nvim",
        build = function(plugin)
            require("lazy").load({ plugins = { plugin.name } })
            local cwd = vim.fn.getcwd()
            local cd = vim.fn.haslocaldir() == 1 and "lcd " or vim.fn.haslocaldir(-1, 0) == 1 and "tcd " or "cd "
            local ok, err = pcall(vim.fn["mkdp#util#install_sync"])
            -- The upstream synchronous installer changes the window-local directory.
            vim.cmd(cd .. vim.fn.fnameescape(cwd))
            assert(ok, err)
            local platform = vim.fn["mkdp#util#get_platform"]()
            local binary = plugin.dir
                .. "/app/bin/markdown-preview-"
                .. platform
                .. (platform == "win" and ".exe" or "")
            assert(vim.fn.executable(binary) == 1, "Markdown preview backend missing; inspect installer output")
        end,
    },
    { "goerz/jupytext.nvim" },
    { "benlubas/molten-nvim", build = ":UpdateRemotePlugins" },
    { "vyfor/cord.nvim" },
    { "MunifTanjim/nui.nvim" },
    { "rcarriga/nvim-notify" },
    { "kawre/leetcode.nvim", dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" } },
    { "ThePrimeagen/vim-be-good" },
}, {
    defaults = { lazy = false, version = false },
    install = { missing = false },
    checker = { enabled = false },
    local_spec = false,
    pkg = { enabled = false },
    rocks = { enabled = false },
    ui = { border = "rounded" },
    performance = { rtp = { disabled_plugins = { "packer_compiled" } } },
})
