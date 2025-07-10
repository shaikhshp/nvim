local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
    PACKER_BOOTSTRAP = fn.system({
        "git",
        "clone",
        "--depth",
        "1",
        "https://github.com/wbthomason/packer.nvim",
        install_path,
    })
    print("Installing packer close and reopen Neovim...")
    vim.cmd([[packadd packer.nvim]])
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
    return
end

-- Have packer use a popup window
packer.init({
    display = {
        open_fn = function()
            return require("packer.util").float({ border = "rounded" })
        end,
    },
})

-- Install your plugins here
return packer.startup(function(use)
    use({ "wbthomason/packer.nvim" })                                                  -- Have packer manage itself
    use({ "nvim-lua/plenary.nvim", commit = "4b7e52044bbb84242158d977a50c4cbcd85070c7" }) -- Useful lua functions used by lots of plugins
    use({ "windwp/nvim-autopairs", commit = "4fc96c8f3df89b6d23e5092d31c866c53a346347" }) -- Autopairs, integrates with both cmp and treesitter
    use({ "numToStr/Comment.nvim", commit = "97a188a98b5a3a6f9b1b850799ac078faa17ab67" })
    use({ "JoosepAlviste/nvim-ts-context-commentstring", commit = "4d3a68c41a53add8804f471fcc49bb398fe8de08" })
    use { 'echasnovski/mini.icons' }
    use({ "kyazdani42/nvim-web-devicons", commit = "563f3635c2d8a7be7933b9e547f7c178ba0d4352" })
    use({ "kyazdani42/nvim-tree.lua", commit = "7282f7de8aedf861fe0162a559fc2b214383c51c" })
    use { 'akinsho/bufferline.nvim', tag = "*", requires = 'nvim-tree/nvim-web-devicons' }
    use({ "moll/vim-bbye", commit = "25ef93ac5a87526111f43e5110675032dbcacf56" })
    use({ "nvim-lualine/lualine.nvim", commit = "a52f078026b27694d2290e34efa61a6e4a690621" })
    use({ "akinsho/toggleterm.nvim", commit = "2a787c426ef00cb3488c11b14f5dcf892bbd0bda" })
    use({ "ahmedkhalf/project.nvim", commit = "628de7e433dd503e782831fe150bb750e56e55d6" })
    use({ "lewis6991/impatient.nvim", commit = "b842e16ecc1a700f62adb9802f8355b99b52a5a6" })
    use({ "lukas-reineke/indent-blankline.nvim", commit = "db7cbcb40cc00fc5d6074d7569fb37197705e7f6" })
    use({ "goolord/alpha-nvim"})
    use({ "folke/which-key.nvim" })
    use({ "neoclide/coc.nvim", branch = "release" })
    use({ "andweeb/presence.nvim" })
    -- Colorschemes
    use({ "folke/tokyonight.nvim", commit = "66bfc2e8f754869c7b651f3f47a2ee56ae557764" })
    use({ "lunarvim/darkplus.nvim", commit = "13ef9daad28d3cf6c5e793acfc16ddbf456e1c83" })
    use({ "rose-pine/neovim", as = "rose-pine" })
    use({ "Shatur/neovim-ayu" })
    use { "catppuccin/nvim", as = "catppuccin" }
        -- Cmp
    use({ "hrsh7th/nvim-cmp" })      -- The completion plugin
    use({ "hrsh7th/cmp-buffer" })    -- buffer completions
    use({ "hrsh7th/cmp-path" })      -- path completions
    use({ "saadparwaiz1/cmp_luasnip" }) -- snippet completions
    use({ "hrsh7th/cmp-nvim-lsp" })
    use({ "hrsh7th/cmp-nvim-lua" })

    -- Github copilot

    use({ "github/copilot.vim" })
    -- Snippets
    use({ "L3MON4D3/LuaSnip" })          --snippet engine
    use({ "rafamadriz/friendly-snippets" }) -- a bunch of snippets to use
    use({ "windwp/nvim-ts-autotag" })
    -- LSP
    use({ "neovim/nvim-lspconfig" }) -- enable LSP
    use({ "williamboman/mason.nvim" }) -- simple to use language server installer
    use({ "williamboman/mason-lspconfig.nvim" })
    -- use({ "nvimtools/none-ls.nvim", requires = {"nvim-lua/plenary.nvim", "nvimtools/none-ls-extras.nvim" }})-- for formatters and linters
    -- new, correct:
    use({ "nvimtools/none-ls.nvim", commit = "0fa6ba7", requires = {"nvim-lua/plenary.nvim", "nvimtools/none-ls-extras.nvim" }})
    use({ "RRethy/vim-illuminate" })
    use({ "onsails/lspkind-nvim" })
    --[[ use({ "lervag/vimtex" }) ]]
    use {
        'lervag/vimtex',
        ft = 'tex',  -- Load VimTeX only for .tex files
        config = function()
            vim.g.vimtex_view_method = 'zathura'  -- Change if using another PDF viewer
            vim.g.vimtex_compiler_method = 'latexmk'
            vim.g.vimtex_compiler_latexmk = {
                options = {
                    '-pdf',
                    '-shell-escape',
                    '-interaction=nonstopmode',
                    '-synctex=1'
                }
            }
            vim.g.vimtex_syntax_enabled = 1
        end
    }
    use({
        "hinell/lsp-timeout.nvim",
        requires = { "neovim/nvim-lspconfig" },
        setup = function()
            vim.g.lspTimeoutConfig = {
                stopTimeout = 1000 * 60 * 5, --     stopTimeout  = 1000 * 60 * 5,  -- ms, timeout before stopping all LSP servers
                startTimeout = 1000 * 10, -- ms, timeout before restart
                silent = false,  -- true to suppress notifications
            }
        end,
    })

    -- Telescope
    use({
        "nvim-telescope/telescope.nvim",
        tag = "0.1.5",
        requires = { { "nvim-lua/plenary.nvim" } },
    })
    -- Treesitter
    use({ "nvim-treesitter/nvim-treesitter" })

    -- Git
    use({ "lewis6991/gitsigns.nvim", commit = "2c6f96dda47e55fa07052ce2e2141e8367cbaaf2" })

    -- VimWithMe
    use({ "ThePrimeagen/vim-be-good" })

    -- Markdown
    use({
        "ellisonleao/glow.nvim",
        config = function()
            require("glow").setup()
        end,
    })

    use({
        "iamcco/markdown-preview.nvim",
        run = "cd app && npm install",
        setup = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" },
    })

    -- Leetcode
    use({ "MunifTanjim/nui.nvim" })
    use({ "rcarriga/nvim-notify" })
    use({
        "kawre/leetcode.nvim",
        opts = {
            arg = "leetcode.nvim",
            lang = "python3",
            domain = "com",
            directory = vim.fn.stdpath("data") .. "/leetcode/",
            logging = true,
        },
    })
    use({ "NvChad/nvim-colorizer.lua" })

    -- JupyterNotebooks support 
    use {"meatballs/notebook.nvim"}
    use { 'dccsillag/magma-nvim', run = ':UpdateRemotePlugins' }

    -- Debuggung and Python
    use {'mfussenegger/nvim-dap'}
    use {'mfussenegger/nvim-dap-python'}
    use { "rcarriga/nvim-dap-ui", requires = {"mfussenegger/nvim-dap", "nvim-neotest/nvim-nio"} }

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if PACKER_BOOTSTRAP then
        require("packer").sync()
    end
end)
