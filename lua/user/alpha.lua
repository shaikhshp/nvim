local status_ok, alpha = pcall(require, "alpha")
if not status_ok then
    return
end

local dashboard_ok, dashboard = pcall(require, "alpha.themes.dashboard")
if not dashboard_ok then
    return
end

dashboard.section.header.val = {
    [[                     _nnnn_                         ]],
    [[                    dGGGGMMb     ,"""""""""""""".   ]],
    [[                   @p~qp~~qMb    | Linux Rules! |   ]],
    [[                   M|@||@) M|   _;..............'   ]],
    [[                   @,----.JM| -'                    ]],
    [[                  JS^\__/  qKL                      ]],
    [[                 dZP        qKRb                    ]],
    [[                dZP          qKKb                   ]],
    [[               fZP            SMMb                  ]],
    [[               HZM            MMMM                  ]],
    [[               FqM            MMMM                  ]],
    [[             __| ".        |\dS"qML                 ]],
    [[             |    `.       | `' \Zq                 ]],
    [[            _)      \.___.,|     .'                 ]],
    [[            \____   )MMMMMM|   .'                   ]],
    [[                 `-'       `--'                     ]],
}
dashboard.section.buttons.val = {
    dashboard.button("f", "  Find file", ":Telescope find_files <CR>"),
    dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
    dashboard.button("p", "  Find project", ":Telescope projects <CR>"),
    dashboard.button("r", "  Recently used files", ":Telescope oldfiles <CR>"),
    dashboard.button("s", "  Restore directory session", "<cmd>lua require('persistence').load()<CR>"),
    dashboard.button("l", "  Restore last session", "<cmd>lua require('persistence').load({ last = true })<CR>"),
    dashboard.button("t", "󱎸  Find text", ":Telescope live_grep <CR>"),
    dashboard.button("c", "  Configuration", ":e $MYVIMRC <CR>"),
    dashboard.button("q", "  Quit Neovim", ":qa<CR>"),
}

dashboard.section.footer.val = "I Use Vim Btw"

dashboard.section.footer.opts.hl = "Type"
dashboard.section.header.opts.hl = "Include"
dashboard.section.buttons.opts.hl = "Keyword"

dashboard.opts.opts.noautocmd = true
alpha.setup(dashboard.opts)
