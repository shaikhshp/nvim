# Keymaps

Both `<leader>` and `<localleader>` are **Space** (`lua/user/keymaps.lua`). Keys are case-sensitive. `n` = Normal, `i` = Insert, `x` = Visual, `s` = Select, `o` = Operator-pending, `t` = Terminal. `<C-...>` is Ctrl, `<A-...>`/`<M-...>` is Alt/Meta, `<CR>` is Enter. Terminal/desktop shortcuts can intercept some combinations.

This catalog covers custom mappings from the current modules, plus explicitly labeled plugin defaults. Plugin mappings require the corresponding plugin and dependencies. Buffer-local and picker mappings override global ones. Which-key groups in `user.whichkey` are labels, not extra commands. Inspect the running buffer with `:verbose nmap <key>`, `:verbose imap <key>`, `:Telescope keymaps` (`<Space>sk`), or picker help.

## Editing And Windows

Source: `lua/user/keymaps.lua`.

| Mode    | Keys                               | Action                                                      |
| ------- | ---------------------------------- | ----------------------------------------------------------- |
| n, x, o | `<Space>`                          | No standalone action; leader prefix                         |
| n       | `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` | Focus left/down/up/right window                             |
| n       | `<C-d>`, `<C-u>`                   | Half-page down/up, center cursor                            |
| n       | `n`, `N`                           | Next/previous search match, center and open folds           |
| n       | `<C-Up>`, `<C-Down>`               | Decrease/increase height by 2                               |
| n       | `<C-Left>`, `<C-Right>`            | Decrease/increase width by 2                                |
| n       | `L`, `H`                           | Next/previous buffer (replace native screen-line motions)   |
| n       | `<A-j>`, `<A-k>`                   | Move line down/up and reindent                              |
| i       | `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` | Move left/down/up/right; completion can override j/k        |
| i       | `jk`, `kj`                         | Leave Insert mode                                           |
| x       | `<`, `>`                           | Indent left/right, keep selection                           |
| x       | `p`                                | Paste without replacing the register with deleted selection |
| x       | `J`, `<A-j>`                       | Move selection down and reindent                            |
| x       | `K`, `<A-k>`                       | Move selection up and reindent                              |

## Main Leader

All keys below are **Normal mode** and prefixed with `<Space>`. Source: `user.keymaps`.

| Keys | Action                                                                 |
| ---- | ---------------------------------------------------------------------- |
| `a`  | Alpha dashboard                                                        |
| `b`  | Telescope buffers                                                      |
| `T`  | Telescope picker command                                               |
| `e`  | Toggle NvimTree                                                        |
| `w`  | Write current buffer                                                   |
| `q`  | Quit window (`:quit`, not force quit)                                  |
| `c`  | Close buffer with `:Bdelete`                                           |
| `h`  | Clear search highlighting                                              |
| `u`  | Redo (`:redo`); plain `u` remains undo and native `<C-r>` remains redo |
| `f`  | Find files                                                             |
| `F`  | Fuzzy search current buffer                                            |
| `P`  | Project history picker                                                 |
| `\|` | Glow Markdown terminal preview                                         |
| `r`  | Source `$MYVIMRC`; cached Lua modules are not reloaded                 |
| `pc` | `:Lazy check`: check updates (Git fetch; not compilation)              |
| `pi` | Install plugins from lockfile (explicit locked API; see below)         |
| `ps` | `:Lazy sync`: clean unused plugins, install/update; change lockfile    |
| `pS` | `:Lazy`: open plugin manager                                          |
| `pu` | `:Lazy update`: intentional upgrades; preserve pins, change lockfile  |
| `sb` | Git branches (same picker as `gb`)                                     |
| `sc` | Colorschemes                                                           |
| `sh` | Help tags                                                              |
| `sM` | Manual pages                                                           |
| `sr` | Recent files                                                           |
| `sR` | Registers                                                              |
| `sk` | Keymaps                                                                |
| `sC` | Commands                                                               |
| `sg` | Live grep project text (needs `rg`)                                    |

Project.nvim changes the working directory automatically using root patterns; file/search commands use the resulting context. Markdown browser preview has buffer-local mappings documented below.

`pi` runs `:lua require('lazy').install({ lockfile = true })` with description "Install plugins from lockfile", honoring existing `lazy-lock.json` entries for missing plugins. Bare `:Lazy install` uses spec targets and can choose newer unpinned revisions; plugins without lockfile entries fall back to spec targets even with the locked API, so new-plugin installation is explicit and deliberate. `:Lazy restore` (no custom mapping) restores already-installed plugins to the current lockfile but does not install missing plugins. Both install forms and restore rewrite the lockfile from installed checkouts: preserve the original baseline before recovering a mixed/drifted installation and follow the [README installation guidance](README.md#installation), including restoring that baseline and restarting between install and restore. **`ps` can remove unused Lazy-managed plugins**, unlike the previous Packer no-auto-clean policy; it is not a reload or baseline restore. There is no compile command.

## Markdown Preview

Source: `lua/user/documents.lua`. These mappings are **Normal-mode and Markdown-buffer-local**. Uppercase `<Space>M` is separate from lowercase notebook `<Space>m`, Lazy manager `<Space>p`, and existing search bindings. Glow's `<Space>\|` terminal preview is unchanged.

| Mode | Keys        | Command / Action                                    |
| ---- | ----------- | --------------------------------------------------- |
| n    | `<Space>Mp` | `MarkdownPreviewToggle`: start/stop browser preview |
| n    | `<Space>Ms` | `MarkdownPreviewStop`: stop browser preview         |

`:MarkdownPreview` starts preview explicitly. The plugin updates the browser as you edit, echoes its localhost URL, and uses the default graphical browser/system opener unless overridden. Opening Markdown alone does not launch preview. Upstream defaults close a buffer's preview when the Markdown buffer becomes hidden. The plugin's backend must be installed; see [README.md](README.md#markdown) for setup and repair instructions.

## Language And Diagnostics

Global Normal mappings from `user.keymaps`; repeated buffer-local mappings on LSP attach are defined in `user.lsp.handlers` with the same actions.

| Mode | Keys                     | Action                                                          |
| ---- | ------------------------ | --------------------------------------------------------------- |
| n    | `<Space>lf`              | Format via `user.formatting` (not Visual range formatting)      |
| n    | `<Space>lF`              | Toggle buffer format-on-save; `:FormatToggle!` toggles globally |
| n    | `<Space>la`              | LSP code action                                                 |
| n    | `<Space>lr`              | LSP rename                                                      |
| n    | `<Space>lh`              | Signature help                                                  |
| n    | `<Space>ll`              | Run CodeLens                                                    |
| n    | `<Space>lq`              | Put diagnostics in location list                                |
| n    | `<Space>lj`, `<Space>lk` | Next/previous diagnostic with float                             |
| n    | `<Space>ld`              | Telescope current-buffer diagnostics                            |
| n    | `<Space>lw`              | Telescope workspace diagnostics                                 |
| n    | `<Space>li`              | LspInfo                                                         |
| n    | `<Space>lm`              | Mason                                                           |
| n    | `<Space>ls`              | Telescope document symbols                                      |
| n    | `<Space>lS`              | Telescope dynamic workspace symbols                             |

These non-leader mappings are **buffer-local after LSP attachment**:

| Mode | Keys  | Action                                                                                |
| ---- | ----- | ------------------------------------------------------------------------------------- |
| n    | `gD`  | Declaration                                                                           |
| n    | `gd`  | Definition                                                                            |
| n    | `K`   | Hover (can supersede VimTeX package help)                                             |
| n    | `gI`  | Implementation                                                                        |
| n    | `grr` | References; matches the native `gr...` family without an ambiguous exact `gr` mapping |
| n    | `gl`  | Line diagnostic float                                                                 |

Format/save eligibility, formatter ordering, fallback selection, and toggle interaction are documented in [README.md](README.md#formatting). CodeLens/other actions require server support.

## Completion And Editing Plugins

Sources: `user.cmp`, `user.autopairs`. Completion keys are Insert mode unless noted. Manual local AI completion is cataloged separately below.

| Mode | Keys             | Action                                                                              |
| ---- | ---------------- | ----------------------------------------------------------------------------------- |
| i    | `<C-j>`, `<C-k>` | Next/previous completion item (override Insert cursor movement when handled by cmp) |
| i    | `<C-b>`, `<C-f>` | Scroll completion docs up/down by 1                                                 |
| i    | `<C-Space>`      | Request completion                                                                  |
| i    | `<C-e>`          | Abort completion                                                                    |
| i    | `<CR>`           | Confirm explicitly selected item; `select = false`                                  |
| i, s | `<Tab>`          | Next completion item; otherwise expand/jump snippet; otherwise fallback             |
| i, s | `<S-Tab>`        | Previous completion item; otherwise jump snippet backward; otherwise fallback       |
| i    | `<M-e>`          | Autopairs fast wrap; choose displayed target, `$` is end key                        |

`<C-y>` is explicitly disabled as a **cmp** mapping, not bound to accept completion. Local AI does not own Tab or `<C-e>`. Autopairs integrates with cmp confirmation but skips that integration for `tex`.

Comment.nvim is configured without custom key overrides (`user.comment`). Its plugin defaults include:

| Mode | Keys                       | Default Action                            |
| ---- | -------------------------- | ----------------------------------------- |
| n    | `gcc`, `gbc`               | Toggle line/block comment on current line |
| n    | `gc{motion}`, `gb{motion}` | Toggle line/block comments over motion    |
| x    | `gc`, `gb`                 | Toggle line/block comments over selection |
| n    | `gco`, `gcO`, `gcA`        | Add comment below/above/at end of line    |

Language-aware comment strings depend on the Treesitter/context-commentstring integration. These are plugin defaults, not keys implemented in `user.keymaps`.

Illuminate's guarded defaults map Normal `<A-n>` / `<A-p>` to next/previous references and Visual/Operator-pending `<A-i>` to its reference text object.

## Local AI

Sources: `lua/user/ai/init.lua`, `context.lua`, and `plugins.lua`. AI uses explicit actions only: no startup, InsertEnter, edit, or after-save inference. Uppercase `<Space>A` does not replace lowercase `<Space>a` (dashboard). Requires local Ollama/curl and an installed exact allowlisted coder tag; chat/completion additionally need their pinned optional plugins. No AI account/authentication or cloud API key is required.

| Mode | Keys             | Action                                                                        |
| ---- | ---------------- | ----------------------------------------------------------------------------- |
| n, x | `<Space>Ac`      | Open CodeCompanion chat with explicit context **unsent**; submit deliberately |
| n, x | `<Space>Ae`      | Explain code/existing diagnostics in a scratch response                       |
| n, x | `<Space>Af`      | Preview proposed correction in scratch diffs; source unchanged until accept   |
| n, x | `<Space>Ar`      | Review scope, publish unverified `Ollama Review` HINTs                        |
| n    | `<Space>Ab`      | Review eligible whole buffer within context budget                            |
| n    | `<Space>Ad`      | Cancel requests and clear current-buffer AI hints, preserving LSP diagnostics |
| n    | `<Space>Ax`      | Cancel pending AI work without clearing existing hints                        |
| n    | `<Space>Am`      | Explicit installed-local-model picker (`:AIModel`)                            |
| i    | `<M-y>`          | **Manual** inline request / next suggestion (Alt-y)                           |
| i    | `<M-]>`, `<M-[>` | Next/previous suggestion; request if none is visible                          |
| i    | `<M-CR>`         | Accept full visible inline suggestion                                         |
| i    | `<M-l>`          | Accept a line of the inline suggestion                                        |
| i    | `<M-x>`          | Dismiss/cancel inline completion                                              |

Normal scoped actions use the enclosing Treesitter function/method or a fallback of the cursor plus up to 20 lines on either side. Visual actions use **full selected lines**, not character/block partial replacements; no AI operator mapping exists. The same session-selected tag serves review/completion; new requests/model changes cancel previous work. Review/Minuet use 4096-token context even for `3b-8k`/`7b-16k` tags. Existing cmp Tab/Shift-Tab and `<C-e>` behavior is unchanged; `<M-e>` remains Autopairs fast wrap.

| Command                | Action                                                                                  |
| ---------------------- | --------------------------------------------------------------------------------------- |
| `:AIModel [exact-tag]` | Pick or explicitly choose an installed allowlisted non-cloud-marked tag                 |
| `:AIContext file`      | Snapshot a small project-relative context file at attachment time for later review/chat |
| `:AIContext!`          | Clear context attachments                                                               |
| `:AIToggle`            | Toggle current-buffer `vim.b.disable_local_ai`, cancel requests, clear its hints        |

Eligibility rejects unnamed/special/read-only/unmodifiable buffers, buffers over 128 KiB, notebooks, and heuristic private/generated/dependency paths. Context is capped at 12,000 rendered bytes, with an optional top-15-line header of at most 2,000 bytes and at most three 4,000-byte attachments. Attachments must resolve within the canonical project root and pass lexical/resolved exclusions; clear/reattach to refresh them. **These are path heuristics, not DLP**: secrets in allowed source/context are not detected. Inspect what you send. See [README.md](README.md#local-ai) for exact tags, server/cloud caveats, transport/artifacts, and verification limits.

The correction **diff panes** have buffer-local Normal mappings:

| Keys       | Action                                                                                                                                    |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `gda`      | Accept only if the original source snapshot/changedtick still matches; replace full scoped lines, call `user.formatting`, **do not save** |
| `gdr`, `q` | Reject and close the preview without changing source                                                                                      |
| `?`        | Open proposal explanation                                                                                                                 |

AI response/explanation scratch windows map Normal `q` to close. Formatting after acceptance is buffer-wide under the normal formatting policy; run relevant tests and inspect real diagnostics before saving. Invalid wrappers/structured output and stale responses are rejected, not semantically verified. Review HINTs use a separate namespace and clear on text change/write/delete; LSP remains authoritative. Chat retains a restricted subset of the pinned plugin's send/regenerate/stop/close and navigation mappings, not tools/slash/context commands. It is asynchronous **nonstreaming**, has no sessions/autosave/background work, and uses stdin transport without chat prompt/response tempfiles; Minuet can still leave local payload tempfiles. Open chat through `Ac`: raw/native CodeCompanion request paths are disabled so they do not bypass the guarded workflow.

## Git

Global **Normal-mode** mappings from `user.keymaps`. Gitsigns is configured in `user.gitsigns` and skips `.ipynb` buffers.

| Keys                     | Action                                                  |
| ------------------------ | ------------------------------------------------------- |
| `<Space>gg`              | Toggle Lazygit terminal (needs `lazygit`)               |
| `<Space>go`              | Telescope Git status                                    |
| `<Space>gb`              | Telescope Git branches                                  |
| `<Space>gc`              | Telescope Git commits                                   |
| `<Space>gd`              | Gitsigns diff against HEAD                              |
| `<Space>gj`, `<Space>gk` | Next/previous hunk                                      |
| `<Space>gl`              | Blame current line                                      |
| `<Space>gp`              | Preview hunk                                            |
| `<Space>gr`              | **Reset current hunk**, discarding its unstaged changes |
| `<Space>gR`              | **Reset buffer**, discarding unstaged buffer changes    |
| `<Space>gs`              | Stage current hunk                                      |
| `<Space>gu`              | Undo staged hunk                                        |

Hunk mappings are Normal-only; there is no custom Visual-range staging/reset mapping. Do not use these against the Python display of notebook JSON. There are no extra custom `[c`/`]c` mappings outside NvimTree.

### Telescope Git Defaults

These are **picker-specific defaults from pinned Telescope 0.1.5**, active in Insert and Normal modes, not extra leader bindings. They replace generic picker behavior. Selecting a Git commit/branch is **not just previewing it**.

| Picker                              | Keys                      | Action                                                                                  |
| ----------------------------------- | ------------------------- | --------------------------------------------------------------------------------------- |
| `git_status` (`<Space>go`)          | `<Tab>`                   | Toggle file staging, rather than multi-select                                           |
| `git_branches` (`<Space>gb` / `sb`) | `<CR>`                    | Checkout selected branch                                                                |
| `git_branches`                      | `<C-t>`                   | Track selected branch (not open tab)                                                    |
| `git_branches`                      | `<C-r>`                   | Rebase onto selected branch                                                             |
| `git_branches`                      | `<C-a>`                   | Create branch                                                                           |
| `git_branches`                      | `<C-s>`                   | Switch branch action                                                                    |
| `git_branches`                      | `<C-d>`                   | Force-delete selected branch (`git branch -D`, confirmation prompt; not preview scroll) |
| `git_branches`                      | `<C-y>`                   | Merge selected branch                                                                   |
| `git_commits` (`<Space>gc`)         | `<CR>`                    | Checkout selected commit, potentially detached HEAD                                     |
| `git_commits`                       | `<C-r>m`                  | Reset current branch to commit, **mixed**                                               |
| `git_commits`                       | `<C-r>s`                  | Reset current branch to commit, **soft**                                                |
| `git_commits`                       | `<C-r>h`                  | Reset current branch to commit, **hard**, potentially losing changes                    |
| `git_bcommits` (command only)       | `<CR>`                    | Checkout selected commit's current file                                                 |
| `git_bcommits`                      | `<C-x>`, `<C-v>`, `<C-t>` | Open selected revision in horizontal/vertical/tab diff                                  |
| `git_stash` (command only)          | `<CR>`                    | Apply selected stash                                                                    |

Read prompts and protect work before checkout/reset/rebase/merge/delete. Do not experiment with these in a dirty repository. The config does not disable these mutating defaults.

## Telescope Navigation

Custom picker mappings in `user.telescope`; only apply **inside Telescope**, not ordinary buffers.

| Mode | Keys                      | Action                                                      |
| ---- | ------------------------- | ----------------------------------------------------------- |
| i    | `<C-n>`, `<C-p>`          | Next/previous prompt history                                |
| i    | `<C-j>`, `<C-k>`          | Next/previous result                                        |
| i    | `<C-c>`                   | Close picker                                                |
| n    | `<Esc>`                   | Close picker                                                |
| i, n | `<Down>`, `<Up>`          | Next/previous result                                        |
| i, n | `<CR>`                    | Default select (Git picker caveats above)                   |
| i, n | `<C-x>`, `<C-v>`, `<C-t>` | Horizontal split, vertical split, tab select                |
| i, n | `<C-u>`, `<C-d>`          | Scroll preview up/down                                      |
| i, n | `<PageUp>`, `<PageDown>`  | Scroll results up/down                                      |
| i, n | `<Tab>`                   | Toggle selection and move to worse result                   |
| i, n | `<S-Tab>`                 | Toggle selection and move to better result                  |
| i, n | `<C-q>`                   | Send all results to quickfix and open it                    |
| i, n | `<M-q>`                   | Send selected results to quickfix and open it               |
| i    | `<C-l>`                   | Complete tag (some symbol/diagnostic pickers specialize it) |
| i    | `<C-_>`                   | Picker mapping help (often Ctrl-/)                          |
| n    | `j`, `k`                  | Next/previous result                                        |
| n    | `H`, `M`, `L`             | Top/middle/bottom result                                    |
| n    | `gg`, `G`                 | Top/bottom result                                           |
| n    | `?`                       | Picker mapping help                                         |

Telescope's default Insert `<Esc>` switches to Normal mode before the custom Normal `<Esc>` closes. Picker-specific mappings and actions take precedence; use help in the actual picker.

## File Tree

All keys are **Normal mode inside NvimTree**. `user.nvim-tree` adds `l` / `<CR>` / `o` to edit, `h` to close a node, and `v` to vertical-split. The rest of this table is the **pinned tree plugin's defaults**, retained by the configuration, not modern unpinned tree defaults.

| Keys                                | Action                                                               |
| ----------------------------------- | -------------------------------------------------------------------- |
| `l`, `<CR>`, `o`, double left-click | Open file/directory                                                  |
| `h`                                 | Close node (custom)                                                  |
| `v`, `<C-v>`                        | Open vertical split                                                  |
| `<C-x>`, `<C-t>`                    | Open horizontal split / tab                                          |
| `<C-e>`                             | Replace tree buffer with file                                        |
| `O`                                 | Open without window picker                                           |
| `<C-]>`, double right-click         | Change root to node                                                  |
| `<`, `>`                            | Previous/next sibling                                                |
| `P`                                 | Parent node                                                          |
| `<BS>`                              | Close current or parent directory                                    |
| `<Tab>`                             | Preview file, keeping tree focus                                     |
| `K`, `J`                            | First/last sibling                                                   |
| `I`, `H`, `U`                       | Toggle Git-ignored / dotfile / custom-filter visibility              |
| `R`                                 | Reload tree                                                          |
| `a`                                 | Create file; trailing `/` creates directory                          |
| `d`, `D`                            | Delete / trash node (mutating; trash needs configured external tool) |
| `r`, `<C-r>`                        | Rename / rename with filename omitted from input                     |
| `x`, `c`, `p`                       | Cut / copy node / paste                                              |
| `y`, `Y`, `gy`                      | Copy name / relative path / absolute path                            |
| `]e`, `[e`                          | Next/previous diagnostic node                                        |
| `]c`, `[c`                          | Next/previous Git-changed node                                       |
| `-`                                 | Change root to parent                                                |
| `s`                                 | Open with system application                                         |
| `f`, `F`                            | Start / clear live filter                                            |
| `q`                                 | Close tree                                                           |
| `W`, `E`                            | Collapse / expand all (large trees can be slow)                      |
| `S`                                 | Search node by path                                                  |
| `.`                                 | Enter command line for node                                          |
| `<C-k>`                             | File information popup (overrides window focus key)                  |
| `g?`                                | Tree help                                                            |
| `m`, `bmv`                          | Toggle bookmark / move bookmarked nodes                              |

## Terminals

Sources: `user.keymaps`, `user.toggleterm`.

| Mode    | Keys                               | Action                                                                                    |
| ------- | ---------------------------------- | ----------------------------------------------------------------------------------------- |
| n       | `<Space>tf`                        | Floating terminal                                                                         |
| n       | `<Space>th`                        | Horizontal terminal, size 10                                                              |
| n       | `<Space>tv`                        | Vertical terminal, size 80                                                                |
| n       | `<Space>tn`                        | Node terminal                                                                             |
| n       | `<Space>tu`                        | ncdu terminal                                                                             |
| n       | `<Space>tt`                        | htop terminal                                                                             |
| n       | `<Space>tp`                        | `python` terminal (PATH executable, not provider)                                         |
| n, i, t | `<C-\>`                            | ToggleTerm open/close mapping (plugin-installed; terminal mapping enabled by its default) |
| t       | `<Esc>`, `jk`                      | Leave Terminal mode in ToggleTerm buffers                                                 |
| t       | `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` | Leave Terminal mode and focus adjacent window in ToggleTerm buffers                       |

The terminal-local custom mappings are attached only to names matching `term://*#toggleterm#*`, not every `:terminal` buffer. Named tools must be installed on PATH.

## Debugging

Global **Normal-mode** mappings in `user.dapui`, installed when nvim-dap is available. DAP UI keys additionally need dap-ui/nvim-nio.

| Keys                                  | Action                            |
| ------------------------------------- | --------------------------------- |
| `<Space>dd`                           | Start/continue debugging          |
| `<Space>dc`                           | Clear breakpoints                 |
| `<Space>db`                           | Toggle breakpoint                 |
| `<Space>dB`                           | Prompt for conditional breakpoint |
| `<Space>dx`                           | Disconnect                        |
| `<Space>dt`                           | Terminate                         |
| `<Space>di`, `<Space>do`, `<Space>dp` | Step into / out / over            |
| `<Space>dl`                           | Run last configuration            |
| `<Space>dr`                           | Restart debug session             |
| `<Space>de`                           | Toggle debug REPL                 |
| `<Space>du`                           | Toggle debug UI                   |

DAP UI opens before launch/attach and closes on termination/exit. Panel-local **Normal** mappings configured in the same module:

| Keys                      | Action                       |
| ------------------------- | ---------------------------- |
| `<CR>`, double left-click | Expand                       |
| `o`                       | Open                         |
| `d`                       | Remove                       |
| `e`                       | Edit                         |
| `r`                       | REPL action                  |
| `t`                       | Toggle                       |
| `q`, `<Esc>`              | Close DAP UI floating window |

Language-specific **buffer-local Normal** mappings:

| Context                     | Keys        | Action                                            |
| --------------------------- | ----------- | ------------------------------------------------- |
| Rust (`user.dap-rust`)      | `<Space>Rb` | Cargo build, select executable, debug binary      |
| Rust                        | `<Space>Rt` | Cargo test --no-run, select artifact, debug tests |
| Attached Java (`user.java`) | `<Space>jo` | Organize imports                                  |
| Attached Java               | `<Space>jt` | Debug nearest test method                         |
| Attached Java               | `<Space>jT` | Debug test class                                  |

Python adds adapter/interpreter configuration but no separate custom test keymaps. See the README for Mason debugpy/codelldb, Cargo, JDK, and Java bundle prerequisites.

## LaTeX

`user.vimtex` attaches the following **buffer-local Normal** mappings for `tex`, `plaintex`, and `bib`. A mapped command still requires VimTeX support in that buffer.

| Keys        | Command / Action                                                    |
| ----------- | ------------------------------------------------------------------- |
| `<Space>xc` | VimtexCompile                                                       |
| `<Space>xf` | VimtexCompileSelected (**Normal only**, not a Visual-range mapping) |
| `<Space>xv` | VimtexView                                                          |
| `<Space>xs` | VimtexStop                                                          |
| `<Space>xx` | VimtexClean                                                         |
| `<Space>xe` | VimtexErrors                                                        |
| `<Space>xz` | VimtexContextMenu                                                   |
| `<Space>xl` | VimtexCountLetters                                                  |
| `<Space>xw` | VimtexCountWords                                                    |
| `<Space>xt` | VimtexStatus                                                        |
| `<Space>xa` | VimtexStopAll                                                       |

VimTeX's **own defaults** use prefix `<localleader>v`, i.e. `<Space>v`, not the upstream `<localleader>l`. Common prefix defaults below are Normal mode except `vL`, which is Normal and Visual; consult `:help vimtex-default-mappings` for the installed plugin's complete text objects, motions, surround operations, and insert mappings.

| Keys                                  | Default Action                                    |
| ------------------------------------- | ------------------------------------------------- |
| `<Space>vi`, `<Space>vI`              | Information / full information                    |
| `<Space>vt`, `<Space>vT`              | Open / toggle table of contents                   |
| `<Space>vq`                           | Log                                               |
| `<Space>vv`, `<Space>vr`              | View / reverse search                             |
| `<Space>vl`, `<Space>vL`, `<Space>vS` | Compile / compile selection / single-shot compile |
| `<Space>vk`, `<Space>vK`              | Stop / stop all                                   |
| `<Space>ve`, `<Space>vo`              | Errors / compiler output                          |
| `<Space>vg`, `<Space>vG`              | Status / all compiler statuses                    |
| `<Space>vc`, `<Space>vC`              | Clean / full clean                                |
| `<Space>vm`                           | Insert mapping list                               |
| `<Space>vx`, `<Space>vX`              | Reload VimTeX / reload state                      |
| `<Space>vs`                           | Toggle main document                              |
| `<Space>va`                           | Context menu                                      |

These defaults can vary with the unpinned VimTeX version and are only installed when not already mapped. The custom `x` namespace avoids the global LSP `l` namespace. LSP attachment maps `K` to hover, which can replace VimTeX's package-documentation `K`.

## Notebooks

Source: `user.notebook`. Mappings are **buffer-local**, automatically attached to `.ipynb` buffers. For an ordinary script use `:NotebookEnable`. Keys use literal `<Space>` in the module. No kernel starts merely from opening a buffer or attaching mappings.

| Mode | Keys                | Command / Action                                                                   |
| ---- | ------------------- | ---------------------------------------------------------------------------------- |
| n    | `<Space>mi`         | MoltenInit: explicitly choose/start kernel                                         |
| n    | `<Space>me{motion}` | MoltenEvaluateOperator: evaluate following motion                                  |
| n    | `<Space>ml`         | MoltenEvaluateLine                                                                 |
| n    | `<Space>mc`         | MoltenReevaluateCell: active evaluated region, not automatic `# %%` cell detection |
| n    | `<Space>mo`         | **noautocmd MoltenEnterOutput**: show/enter output                                 |
| n    | `<Space>mq`         | **MoltenHideOutput**: hide output                                                  |
| n    | `<Space>md`         | MoltenDelete: delete Molten cell, not a source-text delete mapping                 |
| n    | `<Space>mx`         | MoltenInterrupt                                                                    |
| x    | `<Space>mv`         | MoltenEvaluateVisual; clears Ex range and reselects with `gv`                      |

The actual `mo` is **EnterOutput**, not an OpenOutputWindow command: it opens the active output window if closed, then enters it on another invocation. `mq` is **HideOutput**, not deinitialize/quit kernel. The operator uses `me` so motions do not collide with `ml`, `mi`, or other notebook commands. Output windows map Normal `q` and `<Esc>` to close. Initialize before evaluation; missing commands/provider produce warnings.

`:MoltenImportOutput` and `:MoltenExportOutput` are deliberate commands, **not custom keymaps or automatic save actions**. See [README.md](README.md#notebooks) for the fixed provider, kernel registration, text-only output, update/pair preservation, stale-output caveats, and `.ipynb` formatting/Gitsigns exclusions.

## Dashboard And Utility Windows

Alpha-local **Normal** buttons from `user.alpha` do not use leader:

| Keys | Action                                                  |
| ---- | ------------------------------------------------------- |
| `f`  | Find file                                               |
| `e`  | New buffer and Insert mode                              |
| `p`  | Find project                                            |
| `r`  | Recent files                                            |
| `s`  | Restore current directory's saved session (Persistence) |
| `l`  | Restore most recently saved session (Persistence)       |
| `t`  | Find text                                               |
| `c`  | Edit `$MYVIMRC`                                         |
| `q`  | Quit Neovim (`:qa`)                                     |

Session keys are **dashboard-local**, not global `s`/`l` mappings or leader bindings. Open the dashboard with `<Space>a`. `s` uses the current working directory and Git branch; it does not fall back to another directory's last session. `l` restores the most recently saved session across directories. If no matching session exists, the action does nothing. Sessions save automatically on normal exit when at least one named normal buffer exists. Save important edits before restoring; sessions do not back up unsaved text. See [README.md](README.md#sessions) for storage, exclusions, and save controls.

`user.autocommands` maps **Normal `q`** buffer-locally to close quickfix, help, man, and lspinfo windows. Bufferline mouse actions (`user.bufferline`) select on left-click and `Bdelete` on right-click/close. LeetCode and vim-be-good have no additional custom keyboard maps in their config modules; consult their own commands/defaults rather than assuming leader bindings.

## Discord Presence

Source: `lua/user/workflow.lua`. Requires Cord. The uppercase key does not conflict with lowercase `<Space>d...` debugging mappings.

| Mode | Keys       | Command / Action                                                           |
| ---- | ---------- | -------------------------------------------------------------------------- |
| n    | `<Space>D` | `Cord presence toggle`: hide/clear Neovim's Discord activity, or resume it |

Use this before gaming to remove Neovim's presence; press it again to restore the current activity. Hiding pauses updates, so focus changes do not automatically reenable it. This is a session-local toggle, not a saved preference. Other running Neovim instances can publish their own Cord activity independently.

Automatic idle detection is disabled. `:Cord presence hide` and `:Cord presence show` explicitly hide/restore presence.

## Other Plugin Defaults

These keys come from the installed plugins, not extra custom leader mappings. UI keys are Normal-mode unless another mode is specified. Availability depends on the active plugin feature and can change when an unpinned plugin updates.

| Context                                        | Keys                                                         | Action                                                        |
| ---------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------- |
| Alpha                                          | `<CR>`, `<M-CR>`                                             | Activate / queue selected dashboard button                    |
| Which-key                                      | `<Esc>`, `<BS>`                                              | Close / parent prefix                                         |
| Which-key                                      | `<C-d>`, `<C-u>`                                             | Scroll down/up                                                |
| Mason                                          | `<CR>`                                                       | Package details or installation log                           |
| Mason                                          | `i`, `u`, `c`                                                | Install / update-reinstall / check version                    |
| Mason                                          | `U`, `C`, `X`                                                | Update all / check outdated / uninstall                       |
| Mason                                          | `<C-c>`, `<C-f>`, `g?`                                       | Cancel install / filter language / help                       |
| Mason                                          | `q`, `<Esc>`                                                 | Close or clear active filter/search                           |
| Mason                                          | `1`, `2`, `3`, `4`, `5`                                      | All / LSP / DAP / linter / formatter                          |
| Lazy                                           | `?`                                                          | Show manager help and its key mappings                        |
| Lazy                                           | `<CR>`                                                       | Show plugin details                                           |
| Lazy                                           | `K`                                                          | Open link/help/readme/commit/issue under cursor                |
| Glow                                           | `q`, `<Esc>`                                                 | Close preview                                                 |
| DAP variable rows                              | `w`                                                          | Add expression to watches when supported                      |
| DAP console/REPL                               | `G`                                                          | End and enable autoscroll                                     |
| DAP REPL                                       | `<CR>`, `o`                                                  | First action / choose action                                  |
| DAP REPL                                       | `[[`, `]]`                                                   | Previous/next prompt                                          |
| DAP REPL Insert                                | `<Up>`, `<Down>`, `<CR>`                                     | History previous/next / submit                                |
| DAP widgets                                    | `<CR>`, `a`, `o`, double-click                               | First action / available actions                              |
| Projects picker Normal                         | `f`, `b`, `d`, `s`, `r`, `w`, `<CR>`                         | Find / browse / delete history / search / recent / cwd / find |
| Projects picker Insert                         | `<C-f>`, `<C-b>`, `<C-d>`, `<C-s>`, `<C-r>`, `<C-w>`, `<CR>` | Same project actions                                          |
| Live grep / dynamic workspace symbols Insert   | `<C-Space>`                                                  | Fuzzy-refine current results                                  |
| Cached Telescope pickers                       | `<C-x>`                                                      | Remove cached picker, not split                               |
| Telescope command/search history and registers | `<C-e>`                                                      | Edit selected entry                                           |

Project browsing is overridden by `user.project` to open the selected project's NvimTree, replacing the extension's removed Telescope file-browser interface. Most pickers use Enter to perform their context's action, which can insert text, execute commands, change options, or check out Git revisions rather than merely open a file.

Lazy UI defaults above are verified against the installed `stdpath("data")/lazy/lazy.nvim/lua/lazy/view/config.lua` and [published upstream usage documentation](https://lazy.folke.io/usage). Use `?` in the installed manager for its complete bindings; manager actions can install, update, restore, or clean plugins. The UI's install actions are ordinary spec-target installs, not the locked `pi` wrapper.

### VimTeX Editing Defaults

The following are buffer-local TeX defaults; `x/o` means Visual/Operator-pending. Existing mappings can suppress non-forced VimTeX defaults.

| Mode                     | Keys                                                 | Action                                                                          |
| ------------------------ | ---------------------------------------------------- | ------------------------------------------------------------------------------- |
| n                        | `ds$`, `cs$`, `ts$`                                  | Delete / change / toggle math environment                                       |
| n                        | `dse`, `cse`, `tse`, `tss`                           | Delete / change / toggle environment / toggle star                              |
| n, x                     | `<F6>`                                               | Surround with environment                                                       |
| n                        | `dsc`, `csc`, `tsc`, `tsb`                           | Delete / change command / toggle star / command break                           |
| n, x                     | `tsf`                                                | Toggle fraction form                                                            |
| i, n, x                  | `<F7>`                                               | Create command                                                                  |
| n                        | `dsd`, `csd`, `<F8>`                                 | Delete/change delimiters / add delimiter modifiers                              |
| n, x                     | `tsd`, `tsD`                                         | Cycle delimiter modifiers forward/backward                                      |
| i                        | `]]`                                                 | Close delimiter                                                                 |
| n, x, o                  | `%`                                                  | Matching TeX pair                                                               |
| n, x, o                  | `]]`, `][`, `[]`, `[[`                               | Section boundaries                                                              |
| n, x, o                  | `]m`, `]M`, `[m`, `[M`                               | Environment boundaries                                                          |
| n, x, o                  | `]n`, `]N`, `[n`, `[N`                               | Math boundaries                                                                 |
| n, x, o                  | `]r`, `]R`, `[r`, `[R`                               | Beamer frame boundaries                                                         |
| n, x, o                  | `]/`, `]*`, `[/`, `[*`                               | Comment-block boundaries                                                        |
| x, o                     | `id/ad`, `i$/a$`, `iP/aP`, `im/am`, `ie/ae`, `ic/ac` | Delimiter / math / section / item / environment / command objects               |
| VimTeX TOC               | `q`, `<Esc>`, `<CR>`, Space, double-click            | Close / activate-close / activate                                               |
| VimTeX TOC               | `gg`, `h`, `f/F`, `s`, `t`, `r`, `-/+`, `C/L/T/I`    | First / help / filter-clear / numbers / TODO sorting / refresh / depth / layers |
| VimTeX auxiliary windows | `q`, `<Esc>`                                         | Close (exact auxiliary-window availability varies)                              |

In Insert mode, backtick-prefixed shorthands expand math symbols and Greek letters; `<Space>vm` shows the installed complete list. Additional math wrappers `#/`, `#b`, `#f`, `#c`, `#-`, `#B` followed by a character create slashed, bold, fraktur, calligraphic, overline, or blackboard-bold commands. `##` inserts a literal hash.

### Optional Workflow UIs

| Context                       | Keys               | Action                                             |
| ----------------------------- | ------------------ | -------------------------------------------------- |
| LeetCode popup/split          | `q`                | Hide/toggle                                        |
| LeetCode rendered button/info | `<CR>`             | Activate/expand                                    |
| LeetCode console              | `r`, `U`, `H`, `L` | Reset / use testcase / testcase pane / result pane |
| LeetCode results              | Numbered keys      | Select testcase                                    |
| LeetCode main menu            | `p`, `s`, `i`, `c` | Problems / statistics / cookie / cache             |
| LeetCode problems             | `p`, `r`, `d`      | List / random / daily                              |
| LeetCode statistics           | `s`, `l`, `u`      | Skills / languages / update                        |
| LeetCode cookie               | `u`, `d`           | Update / sign out                                  |
| LeetCode cache/sign-in        | `u` / `s`          | Update cache / sign in                             |
| LeetCode back/exit            | `q` / `qa`         | Back / exit Neovim                                 |
| VimBeGood Snake               | `h/j/k/l`          | Snake direction                                    |

VimBeGood's menu selects entries by native deletion (for example `dd`); other games observe native edits. Markdown browser preview exposes commands and `<Plug>` targets; the custom physical keys are listed in the Markdown Preview section. Cord's custom presence toggle is documented above; Notify has no physical default dismiss shortcut configured here. This catalog does not enumerate all native Vim commands, external terminal programs, PDF viewers, or browser controls.
