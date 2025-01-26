local status_ok, alpha = pcall(require, "alpha")
if not status_ok then
	return
end

local dashboard = require("alpha.themes.dashboard")
dashboard.section.header.val = {
--[=[                                .;::::,'                           ]],
[[                          ;:ldk0KXNNNNNXKk:.                       ]],
[[                        ,d0OxxOO0XXNNWWWWNNKxc;.                   ]],
[[ '','..               ,xxkKO0XKKKKkKNWWWWWNNXO::;.                 ]],
[[  ::okxl;...         ;d000XXXX00KOOkONNWWWNXX0:l;;,                ]],
[[    odkOOdc;cl:,'. ..':dOXKK0kk0OO00KKXNNNNXKKc,o,:,               ]],
[[     cdkk00Okxkxl:...,,;cdOxkxk00k0KXXKKXXXKK0l;cccc:              ]],
[[        'ddxxkdoll;...';;:codkOxxKXXKKKXXXXKKk:cclodl.             ]],
[[           cllccd;,l;...';::cldxkk0K0OKKXKK00l;:llodxc             ]],
[[                ldl:,:c;.',;:::cokkKKKKKK00Ooccclllclc             ]],
[[                    .,,coc,.,;:;;;cx0OxkkOkc;:c:lcl::              ]],
[[                         ,::,,,;;;;,,,lo:',;::,::;:;.              ]],
[[                            .l'''',,,,'..;;;;;;::::.               ]],
[[                              .d:,'..........',,,;,                ]],
[[                                 d:cc............';;;:;.           ]],
[[                                   Odlc;;,'....';clc:,;ooc.        ]],
[[                                     ,xccolcc:cllllc:;;oxdk:'.     ]],
[[                                        oxolcolcc::;;;cxkkk0ok.    ]],
[[                                           xloxoddlcloxOO0XXKk:    ]],
[[                                              ,dlcoo:.lkkOOOOXo    ]],
[[                                                   lk'  ,loo:      ]=]
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
	dashboard.button("t", "󱎸  Find text", ":Telescope live_grep <CR>"),
	dashboard.button("c", "  Configuration", ":e $MYVIMRC <CR>"),
	dashboard.button("q", "  Quit Neovim", ":qa<CR>"),
}

local function footer()
-- NOTE: requires the fortune-mod package to work
	-- local handle = io.popen("fortune")
	-- local fortune = handle:read("*a")
	-- handle:close()
	-- return fortune
	return "I Use Vim Btw"
end

dashboard.section.footer.val = footer()

dashboard.section.footer.opts.hl = "Type"
dashboard.section.header.opts.hl = "Include"
dashboard.section.buttons.opts.hl = "Keyword"

dashboard.opts.opts.noautocmd = true
-- vim.cmd([[autocmd User AlphaReady echo 'ready']])
alpha.setup(dashboard.opts)
