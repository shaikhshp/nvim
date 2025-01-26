-- return require('packer').startup(function(use)
--     use {
--         'lervag/vimtex',
--         ft = 'tex',  -- Load VimTeX only for .tex files
--         config = function()
--             vim.g.vimtex_view_method = 'zathura'  -- Change if using another PDF viewer
--             vim.g.vimtex_compiler_method = 'latexmk'
--             vim.g.vimtex_compiler_latexmk = {
--                 options = {
--                     '-pdf',
--                     '-shell-escape',
--                     '-interaction=nonstopmode',
--                     '-synctex=1'
--                 }
--             }
--             vim.g.vimtex_syntax_enabled = 1
--         end
--     }
--     -- Custom Keybindings for VimTeX
--     vim.api.nvim_set_keymap('n', '<leader>xc', '<cmd>VimtexCompile<CR>', { noremap = true, silent = true })
--     vim.api.nvim_set_keymap('n', '<leader>xv', '<cmd>VimtexView<CR>', { noremap = true, silent = true })
--     vim.api.nvim_set_keymap('n', '<leader>xs', '<cmd>VimtexStop<CR>', { noremap = true, silent = true })
--     vim.api.nvim_set_keymap('n', '<leader>xx', '<cmd>VimtexClean<CR>', { noremap = true, silent = true })
--     vim.api.nvim_set_keymap('n', '<leader>xe', '<cmd>VimtexErrors<CR>', { noremap = true, silent = true })
-- end)

vim.api.nvim_set_keymap('n', '<leader>xc', '<cmd>VimtexCompile<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>xf', '<cmd>VimtexCompileSelected<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>xv', '<cmd>VimtexView<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>xs', '<cmd>VimtexStop<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>xx', '<cmd>VimtexClean<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>xe', '<cmd>VimtexErrors<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>xz', '<cmd>VimtexContextMenu<CR>', {noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>xl', '<cmd>VimtexCountLetters<CR>', {noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>xw', '<cmd>VimtexCountWords<CR>', {noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>xt', '<cmd>VimtexStatus<CR>', {noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>xa', '<cmd>VimtexStopAll<CR>', {noremap = true, silent = true })
