local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
local bootstrap = vim.fn.isdirectory(install_path) == 0
if bootstrap then
    vim.fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
    if vim.v.shell_error ~= 0 then
        vim.notify("Unable to install Packer: check Git and network access", vim.log.levels.ERROR)
        return
    end
    vim.cmd.packadd("packer.nvim")
end

local ok, packer = pcall(require, "packer")
if not ok then
    return
end
packer.init({
    auto_clean = false,
    display = {
        open_fn = function()
            return require("packer.util").float({ border = "rounded" })
        end,
    },
})

return packer.startup(function(use)
    use({ "wbthomason/packer.nvim" })
    -- CodeCompanion needs Plenary's newer streaming/error callbacks.
    use({ "nvim-lua/plenary.nvim", commit = "74b06c6c75e4eeb3108ec01852001636d85a932b" })
    use({ "nvim-tree/nvim-web-devicons", commit = "563f3635c2d8a7be7933b9e547f7c178ba0d4352" })

    -- Appearance and navigation.
    use({ "catppuccin/nvim", as = "catppuccin" })
    use({ "folke/tokyonight.nvim", commit = "66bfc2e8f754869c7b651f3f47a2ee56ae557764" })
    use({ "lunarvim/darkplus.nvim", commit = "13ef9daad28d3cf6c5e793acfc16ddbf456e1c83" })
    use({ "rose-pine/neovim", as = "rose-pine" })
    use({ "Shatur/neovim-ayu" })
    use({ "nvim-tree/nvim-tree.lua", commit = "7282f7de8aedf861fe0162a559fc2b214383c51c" })
    use({ "akinsho/bufferline.nvim", tag = "v4.9.1", requires = "nvim-tree/nvim-web-devicons" })
    use({ "moll/vim-bbye", commit = "25ef93ac5a87526111f43e5110675032dbcacf56" })
    use({ "nvim-lualine/lualine.nvim", commit = "a52f078026b27694d2290e34efa61a6e4a690621" })
    use({ "lukas-reineke/indent-blankline.nvim", commit = "db7cbcb40cc00fc5d6074d7569fb37197705e7f6" })
    use({ "goolord/alpha-nvim" })
    use({ "folke/which-key.nvim" })
    use({ "NvChad/nvim-colorizer.lua" })
    use({ "nvim-telescope/telescope.nvim", tag = "0.1.5", requires = "nvim-lua/plenary.nvim" })
    use({ "ahmedkhalf/project.nvim", commit = "628de7e433dd503e782831fe150bb750e56e55d6" })
    use({ "lewis6991/gitsigns.nvim", commit = "2c6f96dda47e55fa07052ce2e2141e8367cbaaf2" })
    use({ "akinsho/toggleterm.nvim", commit = "2a787c426ef00cb3488c11b14f5dcf892bbd0bda" })

    -- Editing and completion: native LSP is the only language-service stack.
    use({ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" })
    use({ "windwp/nvim-ts-autotag" })
    use({ "windwp/nvim-autopairs", commit = "4fc96c8f3df89b6d23e5092d31c866c53a346347" })
    use({ "numToStr/Comment.nvim", commit = "97a188a98b5a3a6f9b1b850799ac078faa17ab67" })
    use({ "JoosepAlviste/nvim-ts-context-commentstring" })
    use({ "RRethy/vim-illuminate" })
    use({ "hrsh7th/nvim-cmp" })
    use({ "hrsh7th/cmp-buffer" })
    use({ "hrsh7th/cmp-path" })
    use({ "hrsh7th/cmp-nvim-lsp" })
    use({ "hrsh7th/cmp-nvim-lua" })
    use({ "saadparwaiz1/cmp_luasnip" })
    use({ "L3MON4D3/LuaSnip" })
    use({ "rafamadriz/friendly-snippets" })
    use({ "onsails/lspkind-nvim" })
    use({ "stevearc/conform.nvim" })

    -- Local AI is loaded only by explicit user actions.
    use({ "olimorris/codecompanion.nvim", tag = "v19.27.0", opt = true, requires = "nvim-lua/plenary.nvim" })
    use({ "milanglacier/minuet-ai.nvim", commit = "3b0a4c5f97b7124d94302c608fbe01c0270d4fbe", opt = true })

    -- Language services and debugging.
    use({ "neovim/nvim-lspconfig" })
    use({ "mason-org/mason.nvim" })
    use({ "mason-org/mason-lspconfig.nvim" })
    use({ "mfussenegger/nvim-jdtls", requires = "mfussenegger/nvim-dap" })
    use({ "mfussenegger/nvim-dap" })
    use({ "mfussenegger/nvim-dap-python" })
    use({ "rcarriga/nvim-dap-ui", requires = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } })

    -- Documents, notebooks, and optional workflow tools.
    use({ "lervag/vimtex" })
    use({ "ellisonleao/glow.nvim" })
    use({ "iamcco/markdown-preview.nvim", ft = "markdown", run = "cd app && npm install" })
    use({ "goerz/jupytext.nvim" })
    use({ "benlubas/molten-nvim", run = ":UpdateRemotePlugins" })
    use({ "vyfor/cord.nvim" })
    use({ "MunifTanjim/nui.nvim" })
    use({ "rcarriga/nvim-notify" })
    use({ "kawre/leetcode.nvim", requires = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" } })
    use({ "ThePrimeagen/vim-be-good" })

    if bootstrap then
        packer.sync()
    end
end)
