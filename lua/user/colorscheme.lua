local colorscheme = "catppuccin-mocha"


local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)

if not status_ok then
  vim.notify("colorscheme " .. colorscheme .. " not found!")
  return
end

vim.cmd("highlight EndOfBuffer guibg=bg guifg=bg")
