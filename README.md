# Neovim Configuration

A personal, modular Lua configuration for programming, technical writing, and notebooks. It combines native Neovim LSP, completion and snippets, explicit tool provisioning, formatting, debugging, fuzzy navigation, VimTeX, Jupyter integration, and on-demand local AI.

This is a configuration to read and adapt, not a general-purpose Neovim distribution. It uses **Lazy (lazy.nvim)**, targets **Neovim 0.12+**, and assumes a Linux-oriented development environment. Language tools, kernels, TeX utilities, and Ollama are separate dependencies; installing plugins alone does not install a complete development environment.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Everyday Use](#everyday-use)
- [UI Panels](#ui-panels)
- [Sessions](#sessions)
- [Language Support](#language-support)
- [Formatting](#formatting)
- [Debugging](#debugging)
- [LaTeX and Markdown](#latex-and-markdown)
- [Notebooks](#notebooks)
- [Local AI](#local-ai)
- [Network and Privacy](#network-and-privacy)
- [Customization](#customization)
- [Maintenance](#maintenance)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Credits](#credits)

## Features

| Area               | Configuration                                                                                                     |
| ------------------ | ----------------------------------------------------------------------------------------------------------------- |
| Appearance         | Catppuccin Mocha, Bufferline, Lualine, indentation guides, file icons, color highlighting, and an Alpha dashboard |
| Navigation         | Telescope file/text/buffer/project searches, NvimTree, Aerial outline, and project.nvim                           |
| Sessions           | Persistence saves editing layouts on exit; Alpha restores directory or last sessions                              |
| Editing            | Treesitter, automatic pairs and tags, context-aware comments, and reference highlighting                          |
| Completion         | nvim-cmp, LuaSnip, friendly-snippets, and LSP/buffer/path sources                                                 |
| Language services  | Native LSP configuration with Mason-managed tools and language-specific overrides                                 |
| Formatting         | Conform, external-formatter preference, selected LSP fallback, and buffer/global save-format toggles              |
| Debugging          | nvim-dap and DAP UI, with Python, Rust, and Java integration                                                      |
| Git and terminals  | Gitsigns, Diffview review/history, Telescope Git pickers, ToggleTerm, and a Lazygit terminal                      |
| Undo history       | Undotree browser over the existing persistent undo history                                                        |
| Documents          | VimTeX with latexmk/zathura, Glow, and browser-based Markdown preview                                             |
| Notebooks          | Jupytext percent-cell editing and explicit Molten kernel execution                                                |
| Local AI           | Ollama-backed reviews, explanations, correction previews, CodeCompanion chat, and manual Minuet completion        |
| Other integrations | Discord Rich Presence through Cord, LeetCode, and vim-be-good                                                     |

The editor defaults to four-space indentation, absolute and relative line numbers, wrapping, mouse support, splits below/right, persistent undo, and system clipboard integration. Swap files and backup/writebackup files are disabled. The terminal font must be configured separately; a Nerd Font is recommended for icons.

The default colorscheme is `catppuccin-mocha`. Lualine uses a customized `iceberg_dark` theme. Tokyo Night, Darkplus, Rose Pine, and Ayu are also declared in the plugin specification.

Both **leader and localleader are Space**. See [KEYMAPS.md](KEYMAPS.md) for the detailed mapping catalog, including modes, buffer-local mappings, and plugin defaults.

## Requirements

### Core Dependencies

| Dependency                      | Purpose                                                                                   |
| ------------------------------- | ----------------------------------------------------------------------------------------- |
| Neovim 0.12+                    | Modern native LSP and Treesitter APIs used by this configuration                          |
| Git                             | Plugin-manager bootstrap and plugin installation                                          |
| `curl`, `tar`, and a C compiler | Treesitter parser downloads and builds                                                    |
| Tree-sitter CLI 0.26.1+         | Modern Treesitter parser installation; verify the installed plugin's current requirements |
| `ripgrep` (`rg`)                | Telescope text search                                                                     |
| Node.js and npm                 | Node-based language tools; optional npm fallback for browser Markdown preview             |
| Clipboard provider              | Access to the system clipboard through `unnamedplus`                                      |
| Nerd Font                       | Recommended for UI icons                                                                  |

`fd` is an optional file-search improvement. Python 3.10+ with venv/pip support is recommended for the notebook provider and Python test scripts.

Use a suitable [Neovim release or nightly](https://github.com/neovim/neovim/releases), rather than assuming your distribution package is recent enough. Some plugins are unpinned and can raise their minimum requirements; check the installed versions, especially Treesitter and VimTeX. The current VimTeX upstream documentation specifies Neovim 0.12.4.

Check `tree-sitter --version` before installing parsers. Prefer the installation methods recommended by [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter), rather than an npm-based CLI installation. Mason can provision `tree-sitter-cli`, but its available version still needs checking.

### Feature Dependencies

| Feature                   | Additional dependencies                                                                                                      |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Python                    | Project Python environment; Pyright/Ruff; Mason debugpy for debugging                                                        |
| Rust                      | Rust/Cargo, Clippy, rustfmt; rust-analyzer; Mason codelldb for debugging                                                     |
| Java                      | Compatible full JDK with `javac`; jdtls; Java debug/test bundles for those features                                          |
| LaTeX                     | TeX distribution, latexmk, zathura, ChkTeX, latexindent and its Perl dependencies; texcount for counting commands            |
| Markdown terminal preview | Glow executable                                                                                                              |
| Markdown browser preview  | Plugin's prebuilt backend (downloaded by its install hook), or Node.js/npm fallback; graphical browser and system URL opener |
| Notebooks                 | Isolated Python provider, Jupytext, Jupyter dependencies, and registered kernels                                             |
| Local AI                  | curl, user-managed Ollama server, and an installed approved coder model                                                      |
| Review and undo panels    | Git 2.31+ for Diffview; external `diff` command for Undotree's optional diff panel                                           |
| Named terminals           | `lazygit`, `node`, `ncdu`, `htop`, or `python`, depending on the terminal used                                               |

Install system dependencies with your preferred package manager or user-local tooling. The configuration does not run `sudo` or automatically provision a JDK, TeX distribution, kernel environment, or Ollama service.

## Installation

### 1. Back Up and Clone

Review the configuration before using it. If you already have a Neovim configuration, move it to an unused backup location first. Do not delete your Neovim data directory as an installation step.

For standard Linux/macOS XDG paths:

```sh
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"

# Run only if an existing configuration is present.
# Choose another destination if nvim.backup already exists.
mv "${XDG_CONFIG_HOME:-$HOME/.config}/nvim" \
   "${XDG_CONFIG_HOME:-$HOME/.config}/nvim.backup"

git clone https://github.com/shaikhshp/nvim.git \
    "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
nvim
```

The examples assume the default Neovim application name. Custom `NVIM_APPNAME` settings change config/data locations. On Windows, use Neovim's actual directories; several workflows here assume Unix-style virtualenv `bin/` paths and Linux tools such as zathura, so Windows support is not guaranteed.

### 2. Install Plugins

`lua/user/plugins.lua` bootstraps Lazy at `stdpath("data")/lazy/lazy.nvim`, checking out stable commit `85c7ff3711b730b4030d03144f6db6375044ae82`. **Fresh first startup clones only the manager**, so it can use the network but does not install the declared plugins. Missing-plugin warnings are expected until explicit installation.

Inside Neovim, install missing plugins from the shipped lockfile baseline, then inspect the manager:

```vim
:lua require("lazy").install({lockfile=true})
:Lazy
```

Wait for installation and its builds to finish, then restart Neovim. `<leader>pi` invokes this same lockfile-based installation API. Markdown browser preview uses the plugin's synchronous prebuilt-backend installer. Molten's `:UpdateRemotePlugins` build needs the Python provider described in [Notebooks](#notebooks); repeat registration after setting up that provider.

**Bare `:Lazy install` is not a lockfile-baseline install.** It uses spec targets and can select the latest unpinned revisions. The locked API honors existing lockfile entries for missing plugins; plugins without entries still fall back to spec targets, so adding a declaration requires an explicit, deliberate installation and revision review. `:Lazy restore` restores **already-installed** plugins to the current lockfile; it does not install missing plugins.

**Both installation forms and restore rewrite `lazy-lock.json` from the installed checkouts.** Locked installation does not repair an already-installed plugin at a different revision, and failed installs can drop missing entries from the rewritten lockfile. Preserve an original baseline copy before recovery. If the installation is mixed (some plugins missing, others at different revisions), install missing plugins with the locked API, restore the original baseline lockfile, restart Neovim to clear Lazy's cached lock data, then run `:Lazy restore`. Retain the original baseline after failures and restart before retrying; do not commit a partial or unintended lockfile.

The authoritative plugin specification is `lua/user/plugins.lua`; the tracked `lazy-lock.json` records the installed baseline revisions for all declared plugins, including Lazy. Preserve deliberate commit/tag pins and review lockfile changes. There is no compile step or generated loader to regenerate.

Declared plugins load eagerly by default (`defaults.lazy = false`, `version = false`), except CodeCompanion and Minuet: both use `lazy = true`, `module = false`, and are loaded explicitly by the guarded AI wrapper through `require("lazy").load()`. Missing-plugin auto-installation and background update checks are disabled (`install.missing = false`, `checker.enabled = false`), as are project-local specs, package metadata, and LuaRocks (`local_spec = false`, `pkg.enabled = false`, `rocks.enabled = false`).

When migrating from Packer, keep old package directories available for rollback until the new setup is verified. The old generated `packer_compiled` runtime plugin is disabled; do not source it manually. Lazy owns plugin loading rather than the old start-package loader. Molten's installation path changes to `stdpath("data")/lazy/molten-nvim`: regenerate the remote-plugin manifest with `:UpdateRemotePlugins` and restart even if the provider path is unchanged. Rollback means restoring the previous configuration and regenerating its remote-plugin manifest, not mixing both managers.

### 3. Provision Language Tools

Mason is configured at startup, but installation is explicit:

```vim
:lua require("user.lsp.mason").provision()
:Mason
```

To include optional Black:

```vim
:lua require("user.lsp.mason").provision({black=true})
```

The helper refreshes the registry and installs missing configured server packages, debug adapters, and selected formatters/utilities. These include jdtls, debugpy, codelldb, Java debug/test bundles, Ruff, latexindent, StyLua, shfmt, Prettier, and the Tree-sitter CLI. It does **not** update already-installed packages or install every optional formatter mentioned in this README.

Provisioning is asynchronous. Wait in `:Mason` for completion. Available configured servers are enabled at startup and after successful provisioning; reopen buffers or restart if needed. Java attaches through its own ftplugin rather than the generic enable list.

### 4. Install Treesitter Parsers

Once the CLI/compiler prerequisites are ready:

```vim
:lua require("user.treesitter").install()
```

Configured parsers cover Python, LaTeX, Rust, Java, Lua, Bash, Markdown/inline Markdown, JSON, HTML, CSS, JavaScript, TypeScript, and TSX.

Installation returns a background task and activates parsers in loaded buffers when it completes. Keep Neovim open; do not immediately quit a headless installation process. Scripted setup can wait explicitly:

```lua
require("user.treesitter").install():wait(300000)
```

Highlighting uses `vim.treesitter.start()` when a parser is available. CSS highlighting is deliberately skipped. Python and CSS retain native indentation; other languages use Treesitter indentation only when an indent query exists.

## Everyday Use

The following is a quick reference, not a replacement for [KEYMAPS.md](KEYMAPS.md). `<leader>` means Space; uppercase and lowercase keys are different.

| Mapping                     | Action                                  |
| --------------------------- | --------------------------------------- |
| `<leader>a`                 | Dashboard                               |
| `<leader>e`                 | File explorer                           |
| `<leader>f`                 | Find files                              |
| `<leader>F`                 | Search current buffer                   |
| `<leader>b`                 | Buffer picker                           |
| `<leader>P`                 | Project picker                          |
| `<leader>sg`                | Live grep                               |
| `<leader>w` / `<leader>q`   | Write / quit current window             |
| `<leader>c`                 | Close buffer with Bdelete               |
| `<C-h/j/k/l>`               | Move between windows                    |
| `H` / `L`                   | Previous / next buffer                  |
| `jk` / `kj` in Insert mode  | Return to Normal mode                   |
| `<leader>gg`                | Lazygit terminal                        |
| `<leader>gp` / `<leader>gs` | Preview / stage Git hunk                |
| `<leader>tf`, `th`, `tv`    | Floating, horizontal, vertical terminal |
| `<C-\>`                     | Toggle terminal                         |

**Git actions can change your worktree.** `<leader>gr` resets a hunk and `<leader>gR` resets buffer changes. Telescope Git pickers include checkout and other modifying actions; consult the catalog before treating them as read-only previews.

Completion uses `<C-j>`/`<C-k>` for selection, `<C-Space>` to request completion, and `<C-e>` to abort. Enter confirms an explicitly selected item. Tab/Shift-Tab navigate completion and snippets. Autopairs fast wrap uses `<M-e>` (Alt-e).

## UI Panels

### Tree and Outline

`<leader>e` still toggles NvimTree in normal editing tabs, now through `user.sidebar.tree_toggle`. Aerial uses global attachment and follows the most recently visited eligible visible source window in the current tab. Special/floating and diff windows are ignored; it does not open automatically or manage source folds.

| Mapping                     | Action                              |
| --------------------------- | ----------------------------------- |
| `<leader>ot`                | Toggle outline, returning to source |
| `<leader>of`                | Open or focus outline               |
| `<leader>on` / `<leader>op` | Next / previous symbol in source    |

When both panels are open, Tree sits above outline in one left column, regardless of opening order. The configured width is 30 columns (clamped on narrow screens); outline opening is refused when there is too little room. Manual window resizing remains available, although layout reconciliation or terminal resizing can reapply configured dimensions. Aerial's plugin `<C-j>`/`<C-k>` mappings are disabled so global window focus works there; NvimTree's existing `<C-k>` file-information exception remains unchanged. These features add no new non-leader source-motion overrides.

Closing a source window makes the outline follow another eligible editor. If an orphaned outline would be the sole remaining window, it is replaced with an ordinary empty editor instead of leaving an unclosable panel.

### Git Review

Diffview opens separate, marked review tabs with its own file panel; the editing tab's Tree/outline stays isolated. `<leader>e` in a review tab only directs you to `<leader>gT`. Default review/history layouts show side-by-side diffs, with a left 30-column file panel or bottom 12-line history panel.

| Mapping      | Action                                                         |
| ------------ | -------------------------------------------------------------- |
| `<leader>gD` | Review project against HEAD, including staged/unstaged changes |
| `<leader>gF` | Review current source file against HEAD                        |
| `<leader>gh` | Review current source file history                             |
| `<leader>gH` | Review project history                                         |
| `<leader>gQ` | Close Diffview review                                          |

File-scoped actions use the remembered visible source filename, passed as an API argument rather than interpolated into an Ex command. Project actions use that source's repository context when available, otherwise the current working directory. `<leader>gE` / `<leader>gT` focus/toggle Diffview's own panel only in review buffers.

The pinned Diffview release can leave a late file-open callback after closing a loading view. `<leader>gQ` tracks active file-open operations, including revisiting cached entries, and refuses to close while content/history is loading. Wait for the revision to finish opening, then press it again; raw `:DiffviewClose` or tab-closing commands do not include this guard.

Project working-tree reviews exclude `.ipynb`, and current-file working-tree review refuses converted notebook buffers: Jupytext displays percent-cell Python while Git stores JSON, so comparing those representations is misleading. File/project history can show historical notebook JSON on both sides. Use a notebook-aware diff tool for working-tree notebook changes; raw Diffview commands do not apply these exclusions.

Diffview defaults are disabled in favor of a small explicit navigation, panel, history, and help map set; see [KEYMAPS.md](KEYMAPS.md#diffview-review). No staging, restoration, or merge-resolution actions are configured there. **Working-tree buffers remain editable**, and existing global Gitsigns/Telescope Git actions are not disabled: this is not a read-only worktree safeguard.

### Undo Browser

`<leader>Ut` toggles Undotree and `<leader>Uf` opens/focuses it from a valid named, normal, editable visible source file. It occupies a bottom row of 12 lines, clamped to one third of terminal height (at least one line). Its optional diff panel opens manually with the native tree-local `D` mapping, to the right in the same bottom row; diff does not open automatically.

Persistent undo was already enabled. Undotree browses that history and can change buffer text when selecting an undo state; it is not a backup or an autosave feature. Sessions still save layouts, not unsaved text. Git 2.31+ and the external `diff` command are user-managed dependencies; this setup does not download system tools.

## Sessions

[persistence.nvim](https://github.com/folke/persistence.nvim) saves the active editing layout on **normal Neovim exit**. It starts with the configuration, but never restores a session automatically. There is no periodic or per-write session save.

Open the Alpha dashboard with `<leader>a`:

| Dashboard key | Action                                                                 |
| ------------- | ---------------------------------------------------------------------- |
| `s`           | Restore the saved session for the current working directory/Git branch |
| `l`           | Restore the most recently saved session across directories             |

These keys are dashboard-local and do not replace normal editing mappings. A missing session is a no-op. The directory action can fall back to a branchless session for the same directory, but does not fall back to another directory's last session. `main` and `master` use the branchless name; other branches have separate sessions when `.git` exists directly in the working directory.

Sessions live under `stdpath("state")/sessions/`, outside this repository. They are keyed by the current working directory, not independent project-root detection; project.nvim's automatic directory changes affect which session is saved/restored. Two instances using the same directory/branch can overwrite the same session; the last save wins.

The session includes file buffers (including hidden buffers), working directory, folds, tabs, split sizes, and cursor positions. Terminal commands, help/unnamed windows, and option/mapping state are excluded from the configured `sessionoptions`. Native sessions do not preserve notebook kernels/results, DAP processes, or AI conversations; special plugin windows are not guaranteed to restore their plugin state.

At least one named normal buffer must exist for automatic saving, so a fresh dashboard-only launch followed by quit does not overwrite an existing session. Returning to the dashboard after opening files can still save, because hidden file buffers count. Each save replaces that directory/branch's previous session; this is not versioned history or crash recovery.

**Sessions are not backups of unsaved text.** Session saving does not write source files. Save important edits before quitting or restoring another layout; force-quitting can still lose changes. Session files are executable Vim scripts sourced during restore, so load only trusted local sessions and protect their directory.

Optional controls from any buffer:

```vim
:lua require("persistence").save()
:lua require("persistence").stop()
:lua require("persistence").start()
```

`save()` saves immediately and bypasses the minimum-buffer safeguard. `stop()` disables exit saving for this Neovim process without deleting existing sessions; `start()` resumes it. Loading a session does not undo `stop()`. Install the missing declared plugin from the baseline with `:lua require("lazy").install({lockfile=true})` or `<leader>pi`, and restart after adopting this configuration. `:Lazy restore` restores existing installations only. Setup lives in `lua/user/persistence.lua`.

## Language Support

Native Neovim LSP is the active language-service stack. Configuration uses `vim.lsp.config()` and `vim.lsp.enable()`, with nvim-lspconfig server definitions and overrides in `lua/user/lsp/settings/`.

| Language / files        | Configured server           |
| ----------------------- | --------------------------- |
| Lua                     | `lua_ls`                    |
| Python                  | `pyright`, `ruff`           |
| Rust                    | `rust_analyzer`             |
| Java                    | `jdtls`, started separately |
| JavaScript / TypeScript | `ts_ls`, `eslint`           |
| HTML / CSS              | `html`, `cssls`             |
| JSON                    | `jsonls`                    |
| Shell                   | `bashls`                    |
| C / C++                 | `clangd`                    |
| Markdown                | `marksman`                  |
| TeX / BibTeX            | `texlab`                    |
| Writing assistance      | `grammarly`                 |

Configured does not mean installed or attached. Only available configured executable commands are enabled. Check `:LspInfo`, `:Mason`, and `:checkhealth` when a feature is missing.

### Common LSP Mappings

| Mapping                     | Action                               |
| --------------------------- | ------------------------------------ |
| `gd` / `gD`                 | Definition / declaration             |
| `gI` / `grr`                | Implementation / references          |
| `K`                         | Hover                                |
| `gl`                        | Diagnostic float                     |
| `<leader>la` / `<leader>lr` | Code action / rename                 |
| `<leader>lj` / `<leader>lk` | Next / previous diagnostic           |
| `<leader>ld` / `<leader>lw` | Buffer / workspace diagnostic picker |
| `<leader>lf`                | Format buffer                        |

Attachment-specific mappings depend on an active server and its capabilities. Ordinary diagnostics use signs, underlines, rounded floats, and severity sorting; ordinary diagnostic virtual text is disabled. AI review hints are separate.

### Python

Pyright uses basic type analysis and supplies navigation, completion, and hover. Ruff supplies linting and code actions; its hover is disabled so Pyright owns hover. Formatting is a separate policy and does not automatically organize imports or apply every Ruff fix.

Pyright and the debug target resolve project Python in this order: active `VIRTUAL_ENV`/`CONDA_PREFIX`, project `.venv`, project `venv`, `~/anaconda3`, then `python3`/`python` on `PATH`. The remote notebook provider and Mason debug adapter are separate interpreters.

### Rust

rust-analyzer checks with Clippy and enables Cargo `allFeatures`. Install the matching toolchain components yourself, for example using an existing rustup installation:

```sh
rustup component add clippy rustfmt
```

Formatting uses toolchain rustfmt. Rust debugging uses Cargo artifact discovery, described below.

### Java

Use a **full JDK 21+ with `javac`**, not just a JRE, and check the requirements of your installed jdtls version. Set `JAVA_HOME` and `PATH` before launching Neovim so its launcher uses the intended runtime:

```sh
export JAVA_HOME=/absolute/path/to/your/jdk
export PATH="$JAVA_HOME/bin:$PATH"
java -version
javac -version
```

The language server's runtime is distinct from the project's Java target version. Project build tools/wrappers can impose additional requirements. The jdtls launcher also requires Python 3.

Opening Java calls `jdtls.start_or_attach()` only when a root marker and executable are available. Aggregate markers such as `gradlew`, `mvnw`, `settings.gradle`, `settings.gradle.kts`, and `.git` take priority over individual build-file markers. A standalone file outside a recognized project does not start this setup.

Each canonical project root gets a cache workspace with a basename and root hash, preventing collisions between same-named projects. `<leader>jo` organizes imports. Java formatting uses the LSP fallback when no external formatter is configured.

## Formatting

`lua/user/formatting.lua` owns manual formatting and `BufWritePre` format-on-save. It skips special, readonly, or unmodifiable buffers, files over **1 MiB**, and names ending in lowercase `.ipynb`.

| Filetype                                    | External formatter policy        |
| ------------------------------------------- | -------------------------------- |
| Python                                      | Ruff format, then optional Black |
| JavaScript / TypeScript / React variants    | prettierd, then Prettier         |
| Rust                                        | rustfmt                          |
| TeX / plain TeX / BibTeX                    | latexindent                      |
| Lua                                         | StyLua                           |
| Shell                                       | shfmt                            |
| JSON / JSONC / HTML / CSS / Markdown / YAML | Prettier                         |
| C / C++                                     | clang-format                     |

Ordered alternatives mean **the first available formatter**, not a chain of all listed tools. Inspect availability with `:ConformInfo`.

Formatting is synchronous with a **2000 ms timeout**. If no external formatter is available, one formatting-capable LSP client is selected, preferring Ruff for Python, rust-analyzer for Rust, jdtls for Java, and texlab for TeX/BibTeX; otherwise the lowest client ID wins. If Conform is missing, the helper attempts the selected LSP directly.

| Mapping / command               | Effect                                 |
| ------------------------------- | -------------------------------------- |
| `<leader>lf`                    | Format manually                        |
| `<leader>lF` or `:FormatToggle` | Toggle save formatting for this buffer |
| `:FormatToggle!`                | Toggle save formatting globally        |

Either disable flag blocks format-on-save. Enabling one does not clear the other. Manual formatting ignores these save-disable flags but still respects buffer eligibility.

## Debugging

nvim-dap owns debugging, with DAP UI opening on launch/attach and closing on termination/exit. Install adapters explicitly with Mason; configuring a language server is not sufficient to debug it.

| Mapping                                    | Action                 |
| ------------------------------------------ | ---------------------- |
| `<leader>dd`                               | Continue / start       |
| `<leader>db`                               | Toggle breakpoint      |
| `<leader>dB`                               | Conditional breakpoint |
| `<leader>di` / `<leader>do` / `<leader>dp` | Step into / out / over |
| `<leader>du`                               | Toggle DAP UI          |

### Python Debugging

The adapter runs from Mason debugpy's own virtualenv. The debugged program uses the project interpreter resolution described in [Python](#python), not the notebook provider. DAP prefers an attached Pyright project root and otherwise searches Python project markers.

### Rust Debugging

Install Mason `codelldb`. In Rust buffers:

- `<leader>Rb` runs `cargo build --message-format=json` and debugs a resulting executable.
- `<leader>Rt` runs `cargo test --message-format=json --no-run` and debugs a test artifact.

Builds are asynchronous and use the nearest `Cargo.toml` root, falling back to the current directory. Multiple artifacts prompt for selection. Failure, no executable, or picker cancellation aborts the launch; no binary path is hard-coded.

### Java Debugging

Install Mason `java-debug-adapter` and `java-test` in addition to `jdtls`. Debug/test bundles are loaded from their package directories. Main-class discovery and hot-code replacement are configured when the debug bundle is present.

`<leader>jt` debugs the nearest test and `<leader>jT` the test class. These mappings warn when required bundles are unavailable.

## LaTeX and Markdown

### LaTeX

VimTeX owns compilation and PDF viewing. Defaults use latexmk with PDF output, nonstop interaction, SyncTeX, and file-line errors, plus zathura as the viewer. Quickfix mode is `0`; inspect compilation errors explicitly.

texlab supplies language features and ChkTeX checks on open/save and edit, but does not build on save. Conform uses latexindent. Mason can install texlab/latexindent, **not** the TeX distribution, latexmk, or PDF viewer.

VimTeX's built-in mapping prefix is `<localleader>v`, which is Space-v here. Custom commands use `<leader>x`; see [KEYMAPS.md](KEYMAPS.md) for their actions. Custom `<leader>xf` is Normal-only, not a Visual-region mapping; VimTeX's Visual `<localleader>vL` is the selected-region workflow. An attached LSP's `K` mapping can replace VimTeX's documentation lookup.

The config does not add `-shell-escape` by default. To opt in for a **trusted** document:

```sh
NVIM_TEX_SHELL_ESCAPE=1 nvim document.tex
```

Shell escape allows TeX to execute external commands. Do not enable it globally for untrusted documents, and review any external TeX/latexmk settings as well.

### Markdown

Markdown buffers enable wrapping and spellcheck. Browser preview uses [iamcco/markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim), with live updates and synchronized scrolling in your default graphical browser.

The following Normal-mode mappings are **Markdown-buffer-local**; uppercase `M` keeps them separate from notebook mappings under lowercase `m`:

| Mapping / command                       | Action                 |
| --------------------------------------- | ---------------------- |
| `<leader>Mp` / `:MarkdownPreviewToggle` | Toggle browser preview |
| `<leader>Ms` / `:MarkdownPreviewStop`   | Stop browser preview   |
| `:MarkdownPreview`                      | Start browser preview  |

Preview starts only when requested. The server listens on localhost by default, and the URL is echoed in Neovim so it can also be opened manually. On Linux, automatic launch uses the system URL opener (`xdg-open`) unless you explicitly configure the plugin's browser override. A graphical browser/session is needed; remote/headless sessions may need a separate browser-opening arrangement. Upstream defaults close a buffer's preview when that Markdown buffer becomes hidden, not merely when focus moves to another window.

The plugin is loaded at startup so its buffer-local commands are registered on the first Markdown filetype event. Its Lazy build hook delegates to `lua/user/markdown-preview.lua`; runtime settings and keymaps remain in `lua/user/documents.lua`. The build first loads the plugin through the manager, calls upstream `mkdp#util#install_sync()` synchronously to download and finish installing the prebuilt backend, restores the working directory, and checks the platform executable under `plugin.dir/app/bin/`. If that hook failed or an older installation has no backend, rerun the guarded build inside Neovim:

```vim
:Lazy build markdown-preview.nvim
```

Restart afterward. The raw upstream installer can change the current window's working directory to the plugin's `app` directory; the configured build restores it even on installer failure. An already-installed plugin may not rerun its build automatically, so the explicit build above repairs an incomplete backend without a bulk plugin update or compile step.

If prebuilt binaries are unavailable for your platform, the supported alternative is `npm install` in **this plugin's `app` directory**, using Node.js/npm. Do not run it in this configuration repository. Without either a working prebuilt executable or installed app dependencies, the backend cannot start. Inspect `:messages` for errors and the echoed preview URL for browser-opening problems.

The separate terminal preview remains unchanged: use `:Glow` or `<leader>|` after installing Glow. See [KEYMAPS.md](KEYMAPS.md#markdown-preview) for the browser-preview mappings.

## Notebooks

Notebooks use **goerz/jupytext.nvim** for editing and **Molten** for explicit kernel execution. These are separate responsibilities: saving text is not the same operation as exporting live execution results.

### Set Up the Remote Provider

`user.python` sets the Python remote-plugin host before plugin discovery. The default is:

```text
stdpath("data")/python-provider/bin/python
```

On a standard Linux setup, that is `~/.local/share/nvim/python-provider/bin/python`. Set `NVIM_PYTHON_HOST` to an absolute executable path to override it; Jupytext must be installed beside that executable. A project virtualenv is not implicitly substituted for the provider.

Create the isolated provider using a Unix-style virtualenv:

```sh
provider="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/python-provider"
python3 -m venv "$provider"
"$provider/bin/python" -m pip install --upgrade pip
"$provider/bin/python" -m pip install pynvim jupyter_client jupytext nbformat ipykernel
"$provider/bin/python" -m ipykernel install --user \
    --name nvim-provider --display-name "Python (Neovim provider)"
```

`pynvim` hosts the remote plugin, `jupyter_client` connects to kernels, Jupytext converts notebooks, `nbformat` supports output import/export, and `ipykernel` supplies this example Python kernel. The text-only setup does not require image-rendering dependencies.

After dependencies and Molten are installed, run **from this configuration**:

```vim
:UpdateRemotePlugins
```

Then restart. Repeat registration if the provider was missing during the plugin build, its path changed, or Molten moved from a Packer package directory to `stdpath("data")/lazy/molten-nvim`. The manifest contains plugin paths, so migration requires regeneration even with an unchanged provider. Inspect the actual paths with:

```vim
:lua print(require("user.python").host, require("user.python").jupytext)
```

The provider hosts Molten; the selected kernelspec determines where notebook code executes. For project-specific dependencies, install/register a kernel from that project's environment with a unique name rather than replacing the provider.

### Edit and Execute

Opening `.ipynb` displays Python in `py:percent` format. Jupytext uses `update = true` and `autosync = true`; saves update notebook JSON and synchronize existing pairs. A provider-backed YAML parser handles list-valued metadata. If dependencies are missing, notebooks can remain raw JSON; fix the setup and restart before editing them as code.

Mappings are buffer-local to `.ipynb`. Ordinary scripts opt in with `:NotebookEnable`. Neither opening a notebook nor enabling mappings starts a kernel or evaluates code.

| Mapping              | Action                                    |
| -------------------- | ----------------------------------------- |
| `<leader>mi`         | Initialize and select a registered kernel |
| `<leader>me{motion}` | Evaluate motion                           |
| `<leader>ml`         | Evaluate line                             |
| Visual `<leader>mv`  | Evaluate selection                        |
| `<leader>mc`         | Reevaluate an existing Molten region      |
| `<leader>mo`         | Show/enter active output window           |
| `<leader>mq`         | Hide output window                        |
| `<leader>md`         | Delete Molten cell state, not source text |
| `<leader>mx`         | Interrupt execution                       |

Molten regions are evaluated ranges, not automatically discovered `# %%` cells. Output is text-only with virtual text enabled; images/HTML and automatic output-window opening are disabled. Kernel initialization is always explicit.

### Preserve Outputs and Metadata

Notebook conversion writes are synchronous. Paired `.py` synchronization remains asynchronous: wait for completion and reload external changes before further saves.

Jupytext update/sync is intended to preserve outputs, execution counts, and cell/notebook metadata where cells can be matched. **Retained output may be stale after edits.** Reordering, splitting, deleting, or substantially changing cells can affect matching. Keep the original notebook, use backups/version control, and review JSON diffs; a percent script does not contain all rich notebook output.

Saving does **not** export live Molten results. Use `:MoltenExportOutput` deliberately and consult its help for path/overwrite options. Saved results can likewise be imported explicitly with `:MoltenImportOutput`. There is no export-on-save autocmd.

Formatting and Gitsigns skip `.ipynb` because displayed Python differs from on-disk JSON. Global Git mappings still exist; do not use them for notebook hunk operations. Paired `.py` files are ordinary files and can format/show hunks, affecting later synchronization. Avoid simultaneous writers to the same notebook/pair.

## Local AI

Local AI is **on demand**, owned by `lua/user/ai/`. Startup registers the integration without requesting Ollama or loading CodeCompanion/Minuet. Entering Insert mode, editing, and saving do not trigger inference. There is no automatic completion or after-save review.

Model output is an **unverified suggestion**, not a replacement for LSP/compiler diagnostics, tests, or human review.

### Service and Models

Requests use the fixed endpoint `http://127.0.0.1:11434` through curl with proxies and redirects disabled. No cloud API key or AI account is required. Install/manage Ollama yourself; the configuration does not install it, pull models, or start/restart its service.

Optional, explicit model downloads:

```sh
ollama pull qwen2.5-coder:3b
# Optional larger model:
ollama pull qwen2.5-coder:7b
ollama list
```

Only these exact installed tags are accepted:

| Tag                    | Notes                                |
| ---------------------- | ------------------------------------ |
| `qwen2.5-coder:3b`     | Default                              |
| `qwen2.5-coder:7b`     | Larger alternative                   |
| `qwen2.5-coder:3b-8k`  | Must already exist locally to select |
| `qwen2.5-coder:7b-16k` | Must already exist locally to select |

Unknown, shorthand, uninstalled, and remote-metadata-marked tags are rejected without automatic fallback. `:AIModel` or `<leader>Am` opens the picker; `:AIModel qwen2.5-coder:7b` selects explicitly. Selection is session-local, shared by review/completion, and cancels previous work.

Review and Minuet force `num_ctx = 4096` for every allowed tag. Chat defaults to the selected model and 4096 context, but exposes editable model/context settings; **that chat context default is not transport-enforced**. Larger-looking tag names do not enlarge review/completion context.

Loopback Ollama can itself host cloud-backed models. This integration checks the allowlist and excludes inventory entries with remote metadata, but that is not a general privacy guarantee. Where supported, configure `OLLAMA_NO_CLOUD=1` in the **Ollama server's environment** for additional protection. Service changes are your responsibility.

### Actions and Scope

| Mapping / command                 | Action                                              |
| --------------------------------- | --------------------------------------------------- |
| Normal/Visual `<leader>Ac`        | Open chat with explicit context, initially unsent   |
| Normal/Visual `<leader>Ae`        | Explain scope/diagnostics in a scratch window       |
| Normal/Visual `<leader>Ar`        | Review scope                                        |
| Normal `<leader>Ab`               | Review eligible buffer                              |
| Normal/Visual `<leader>Af`        | Propose correction in scratch diffs                 |
| `<leader>Ad`                      | Cancel and clear current-buffer AI hints            |
| `<leader>Ax`                      | Cancel pending work without clearing existing hints |
| `:AIToggle`                       | Toggle current-buffer AI eligibility                |
| `:AIContext file` / `:AIContext!` | Attach project-file snapshot / clear attachments    |

Normal scoped actions use the enclosing Treesitter function/method when available, otherwise the cursor plus up to 20 lines on either side. Visual actions use **all full lines touched**, including character/block selections; they are not partial-character replacements. There is no AI operator-pending mapping. Uppercase `A` preserves lowercase `<leader>a` for the dashboard.

Eligible buffers must be named, loaded, normal, writable/modifiable, and at most **128 KiB**. Lexical and resolved paths are checked against notebook, private-file, generated, and dependency exclusions. Examples include `.env*`, keys/credentials, `.git`, `node_modules`, `target`, `dist`, and private configuration directories.

**These are path heuristics, not DLP or content-based secret scanning.** Secrets can exist in otherwise allowed code, comments, diagnostics, or attachments. Inspect what you send.

Review/chat rendering includes line-numbered source, scoped non-AI diagnostics, and optionally up to 15 preceding file-header lines if their text fits within 2,000 bytes. The combined rendered budget is **12,000 bytes**, including attachments and wrappers; oversized requests are refused rather than silently truncated. This byte limit is distinct from token context.

Attachments are at most three files of 4,000 bytes each and must be existing regular files within the matching canonical project root. Exclusions and symlink-escape checks apply. Eligible loaded unsaved text is used when available; otherwise disk text is read. Attachments are snapshots, not live references: clear/reattach to refresh them. Minuet uses separate bounded prefix/suffix context, not attachments.

### Review and Correction

Reviews create HINT diagnostics in the separate `UserOllamaReview` namespace, source `Ollama Review`. They do not replace LSP diagnostics and clear on text changes, write, or buffer deletion.

Corrections snapshot the source and changedtick, then show original/proposed scratch diffs without editing the source. In either pane:

- `gda` accepts.
- `gdr` or `q` rejects.
- `?` shows the explanation.

Acceptance refuses stale source, replaces the original full-line scope, and invokes **buffer-wide formatting**, which may affect lines outside the scope. It does not save. Recheck diagnostics and run tests before writing.

Malformed structured output, invalid finding locations, and correction wrappers are rejected; stale asynchronous responses are discarded. These guards do not establish semantic correctness.

### Chat and Manual Completion

Chat opens with supplied context **unsent**. Review/edit it and submit deliberately using CodeCompanion's chat send mapping. Tools, slash commands, rules/skills autoload, MCP, background work, automatic editor context, sessions, and autosave are disabled.

Use the integration mappings rather than raw `:CodeCompanion`, `:CodeCompanionChat`, or `:CodeCompanionCmd` request paths. Native/unregistered requests are rejected. Supported chat submissions cancel overlapping AI work.

The custom chat transport is asynchronous and nonstreaming (`stream = false`), sending JSON through curl stdin and returning the complete response. It creates no chat prompt/response transport tempfiles. **Minuet may create local payload tempfiles**, and live tests retain synthetic reports; do not infer zero artifacts.

Insert-mode completion is separate from cmp and manual-only:

| Mapping           | Action                                                 |
| ----------------- | ------------------------------------------------------ |
| `<M-y>`           | Request / next suggestion                              |
| `<M-]>` / `<M-[>` | Next / previous suggestion; request if none is visible |
| `<M-CR>`          | Accept suggestion                                      |
| `<M-l>`           | Accept one line                                        |
| `<M-x>`           | Dismiss/cancel completion                              |

`<M-...>` means Alt/Meta and depends on terminal key handling. `<M-e>` remains Autopairs fast wrap, and cmp retains its own `<C-e>` and Tab behavior. Completion checks origin buffer/window/cursor, changedtick, and Insert mode. Cancelling a client request does not guarantee immediate server-side model-resource release.

## Network and Privacy

Local AI transport does **not** make the entire configuration offline or private:

- Lazy bootstrap clones the manager on first startup. Explicit installation (including `require("lazy").install({lockfile=true})`), `:Lazy restore`, `:Lazy check` (Git fetch), `:Lazy update`, and `:Lazy sync` can use the network; automatic missing-plugin installs and background update checks are disabled.
- Plugin builds (including Markdown backend downloads), Mason provisioning, and parser installation/updates can use the network.
- JSON language-service schemas can refer to remote URLs.
- Grammarly is configured when its executable is available; review that service separately.
- Cord is set up during startup when installed and can publish Discord Rich Presence. Normal-mode `<leader>D` toggles presence off/on (`:Cord presence toggle`): hide it before gaming or working on sensitive projects, then press again to restore it. Hiding remains in effect across focus changes but is not saved across Neovim restarts; other Neovim instances can still publish their own activity.
- LeetCode has account/network behavior and logging, with storage under `stdpath("data")/leetcode`.
- Notebook kernels and TeX shell escape execute code and should only be used with trusted inputs.

Review `lua/user/workflow.lua`, the plugin specification, and enabled language services before adopting the configuration. Avoid sharing local test reports or generated files without inspecting them for paths, process information, and content.

Cord's automatic idle detection is disabled. See [KEYMAPS.md](KEYMAPS.md#discord-presence) for the presence controls.

## Customization

### Repository Layout

```text
init.lua                   Startup orchestration and module load order
lua/user/
  options.lua              Editor defaults
  keymaps.lua              Global mappings
  plugins.lua              Lazy bootstrap, declarations, pins, and build hooks
  formatting.lua           Manual/save formatting policy
  persistence.lua          Session saving and native restore scope
  sidebar.lua              Shared Tree/outline layout and visible source tracking
  aerial.lua               Global outline attachment and panel settings
  diffview.lua             Isolated Git review/history tabs and safe action maps
  undotree.lua             Pre-plugin globals, source guards, and bottom-row layout
  python.lua               Remote provider and project interpreter resolution
  lsp/                     Native LSP setup, handlers, and server overrides
  ai/                      Local transport, context, review, chat, completion
  java.lua                 Project-scoped jdtls setup
  dap-python.lua           Python adapter configuration
  dap-rust.lua             Cargo artifact discovery and Rust debugging
  notebook.lua             Jupytext/Molten configuration and mappings
  vimtex.lua               TeX globals and custom mappings
  documents.lua            Document preview setup
  workflow.lua             Cord and LeetCode
  ...                      UI, navigation, completion, and terminal modules
ftplugin/java.lua          Java filetype entrypoint
tests/                     Focused configuration and integration checks
lazy-lock.json             Tracked installed plugin revision baseline
KEYMAPS.md                 Detailed mapping catalog
AGENTS.md                  Repository maintenance guidance for coding agents
.stylua.toml               Lua formatting conventions
```

Options and the Python provider load first; VimTeX globals load before plugins. Completion, formatting, LSP, UI/navigation, documents/notebooks, debugging, and workflow setup follow. Java starts from its ftplugin.

The main plugin specs pin Aerial to `28fe6e822ae344544c379d60fcb13c9519a1f08a`, Diffview to `4516612fe98ff56ae0415a259ff6361a89419b0a`, and Undotree to `6fa6b57cda8459e1e4b2ca34df702f55242f4e4d`. Undotree's spec `init` wrapper calls `user.undotree.init()` before plugin loading. Startup then loads `user.aerial`, calls `user.sidebar.setup()`, loads `user.diffview`, and calls `user.undotree.setup()`.

Keep new feature setup under `lua/user/` and require startup modules from `init.lua`; keep the entrypoint focused on orchestration. Edit the appropriate owning module rather than adding a second setup call elsewhere.

Common customization locations:

| Change                   | File                                            |
| ------------------------ | ----------------------------------------------- |
| Theme                    | `lua/user/colorscheme.lua`                      |
| Editor options           | `lua/user/options.lua`                          |
| Global mappings          | `lua/user/keymaps.lua`                          |
| Which-key group labels   | `lua/user/whichkey.lua`                         |
| Plugins and versions     | `lua/user/plugins.lua`                          |
| Server-specific settings | `lua/user/lsp/settings/`                        |
| Formatters and policy    | `lua/user/formatting.lua`                       |
| Discord/LeetCode         | `lua/user/workflow.lua` and plugin declarations |

Update [KEYMAPS.md](KEYMAPS.md) when changing mappings. Lua uses four-space indentation and double quotes, with formatting controlled by `.stylua.toml`.

## Maintenance

- `<leader>pi` / `:lua require("lazy").install({lockfile=true})` installs missing plugins using existing `lazy-lock.json` entries. `:Lazy restore` returns already-installed plugins to the current lockfile but does not install missing plugins. Both operations rewrite the lockfile; preserve the original baseline and follow the installation section's recovery sequence when plugins are missing and existing revisions have drifted. Restart after specification changes; no compile step is needed.
- Bare `:Lazy install` uses spec targets, can choose newer unpinned revisions, and rewrites the lockfile. New plugins without lockfile entries fall back to spec targets even with the locked API: install deliberately and review resulting revisions and lockfile changes.
- `:Lazy check` checks for updates with Git fetch; `:Lazy` opens the manager and `:Lazy log` shows recent updates. Inspect manager task/build output and `:messages` when builds fail.
- `:Lazy update` is for intentional upgrades and changes the lockfile. Preserve spec commit/tag pins and review/commit intended `lazy-lock.json` changes along with spec changes.
- **`:Lazy sync` cleans unused Lazy-managed plugins, installs missing plugins, and updates plugins/lockfile.** Unlike the prior Packer `auto_clean = false` policy, it can remove obsolete installations; it is not a harmless reload or a baseline restore. `:Lazy clean` explicitly removes unused Lazy-managed plugins. Old Packer package directories are separate and should be inspected deliberately, not deleted as a blanket migration step.
- `:TSUpdate` updates parsers after Treesitter changes and is the Lazy build hook; it does not replace explicit configured parser installation through `require("user.treesitter").install()`.
- `<leader>r` sources the entrypoint but does **not** clear cached Lua modules. Restart after changes that need reinitialization.
- Keep Python caches, virtualenvs, local plugin data/state, logs, credentials, and live-test artifacts out of version control; keep `lazy-lock.json` tracked. `nvim-pack-lock.json` is not the active Lazy lockfile.

CodeCompanion is pinned to `v19.27.0`, Minuet to `3b0a4c5f97b7124d94302c608fbe01c0270d4fbe`, and Plenary to `74b06c6c75e4eeb3108ec01852001636d85a932b`. Check the full plugin specification for other pins. Copilot, CoC, null-ls, Magma, and impatient are not configured alternative stacks.

## Verification

There is no general build/CI pipeline. Focused checks live under `tests/`; run them from the repository root. A passing stubbed test does not prove that real servers, adapters, kernels, or model answers work correctly.

### Startup and Isolated Checks

```sh
nvim --headless '+quit'
nvim --headless -u NONE -i NONE -l tests/plugin_manager_config.lua
nvim --headless -u NONE -i NONE -l tests/ai_config.lua
nvim --headless -u NONE -i NONE -l tests/formatting_config.lua
nvim --headless -u NONE -i NONE -l tests/persistence_config.lua
nvim --headless -u NONE -i NONE -l tests/ui_config.lua
lua tests/notebook_config.lua
```

| Check                     | Coverage                                                                                                                                   |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Startup smoke             | Loads the installed configuration; distinguish missing-plugin warnings from runtime errors                                                 |
| Plugin manager specs      | Isolated sourced specs: bootstrap guards, pins, eager/AI loading policy, build hooks, and disabled auto-install/check/package flags        |
| AI configuration          | Synthetic/stubbed startup, eligibility/context/model guards, separate hints, stale callbacks, correction acceptance, and manual completion |
| Formatting configuration  | Stubbed formatter ordering, LSP fallback, toggles, exclusions, and errors                                                                  |
| Persistence configuration | Stubbed missing-plugin guard, session options, exit-save setup, and dashboard restore actions                                              |
| UI configuration          | Stubbed panel options, safe mappings/source selection, bottom undo globals, and loading-time close guards                                  |
| Notebook configuration    | Stubbed provider/plugin guards, settings, mapping scope, and explicit initialization                                                       |

The isolated plugin-manager spec test sources configuration with manager/process stubs, without a Python provider or real process/network calls; it does not install plugins or validate live builds. The isolated AI test also makes no real process/network requests. The startup smoke test is not an isolated first-install test: if Lazy is missing, normal startup clones the manager. No new migration/live-test pass is implied by these commands or coverage descriptions.

The UI configuration test uses stubbed plugins and makes no source writes or process/network calls. Existing diagnostics remain available through Telescope and `<leader>lq`; no Trouble plugin is installed by this feature.

### UI Integration

With the declared plugins already installed, Git, `diff`, and the configured provider Python with `pynvim`:

```sh
provider="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/python-provider"
"$provider/bin/python" tests/ui_live.py
```

The opt-in harness uses disposable source files and a temporary Git repository with fixture commits. It checks both sidebar opening orders, real symbols, rapid focus and tab isolation, narrow-screen resizing, last-source cleanup, bottom undo/diff placement, undo-node selection, loaded diffs/history, notebook working-tree exclusions, and session restoration. It exercises actual Normal-mode mappings and verifies that fixture source/index contents are not written by the UI actions. No commits are made in this configuration repository, and no tools/plugins/models are installed. A watchdog signals only the harness's own child on a stall; fixture data is removed afterward. Normal configuration startup still enables its configured integrations, including Cord.

### Notebook Integration

Use the actual configured provider paths if overridden:

```sh
provider="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/python-provider"
"$provider/bin/python" tests/notebook_roundtrip.py "$provider/bin/jupytext"
"$provider/bin/python" tests/notebook_live.py

# Optional explicit kernel execution/output checks:
"$provider/bin/python" tests/notebook_live.py --kernel nvim-provider
```

The CLI round trip checks update/pair preservation on disposable fixture copies. The embedded-Neovim test checks notebook editing, list metadata, stale retained output, and paired sync; the optional kernel argument adds execution/output-window checks. These checks do not automatically export live Molten output.

### Opt-In AI Integration

With the pinned plugins, provider `pynvim`, curl, a running local Ollama service, and already-installed approved models:

```sh
"$provider/bin/python" tests/ai_live.py --model qwen2.5-coder:3b
```

Without `--model`, the harness benchmarks 3b and 7b and integrates the first. The option is repeatable. Pin validation resolves installed plugin directories through `require("lazy.core.config").plugins[name].dir` and compares their Git revisions with the declared tag/commit pins, rather than assuming Packer paths. Tests send synthetic prompts only, do not pull models/provision dependencies/restart the daemon, and do not save source buffers. Retained reports contain synthetic prompts/responses and local process/resource information; inspect them before sharing.

Schema validation and integration success are not model-accuracy tests. Performance depends on hardware, cold loading, context, and competing jobs; no portable speed or memory guarantee is implied. Interactive LSP/DAP, Java bundles, TeX viewing, Markdown preview, and output export require separate checks with their real dependencies.

## Troubleshooting

| Symptom                           | What to check                                                                                                 |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| Missing icons or incorrect glyphs | Select a Nerd Font in your terminal; the GUI font option does not configure terminal fonts                    |
| Clipboard unavailable             | `:checkhealth` and an installed clipboard provider appropriate to your session                                |
| Plugin feature missing            | `:Lazy`, task/build output, `:messages`, lockfile baseline, and restart after installation                    |
| LSP not attached                  | `:LspInfo`, `:Mason`, executable availability, filetype, and project root                                     |
| Treesitter highlighting missing   | CLI/compiler versions, parser installation, and `:checkhealth`; CSS is deliberately excluded                  |
| Formatting not running            | `:ConformInfo`, formatter/LSP availability, both save-disable flags, buffer size/type, and timeout            |
| Java not attached                 | Recognized root, jdtls executable, compatible full JDK, `JAVA_HOME`, and launcher requirements                |
| Debug launch fails                | Adapter installation, target interpreter/toolchain, Java bundles, or Cargo build/artifact output              |
| Notebook opens as JSON            | Provider/Jupytext paths and executable availability; restart after correcting dependencies                    |
| Molten commands missing           | Provider dependencies, `:UpdateRemotePlugins`, restart, and provider/Molten health checks                     |
| Notebook output absent or stale   | Explicit kernel initialization/import; saving does not export live results, and retained results may be stale |
| AI unavailable                    | Local Ollama/curl availability, exact installed tag, eligibility/context limits, and buffer AI-disable flag   |
| Alt completion keys not received  | Terminal key encoding; verify Alt/Meta and Alt-Enter support                                                  |
| Removed plugin still active       | Inspect Lazy state and obsolete Packer directories; `:Lazy clean` removes only unused Lazy-managed plugins    |

Useful health commands include `:checkhealth`, `:checkhealth provider`, and `:checkhealth molten` where supported by the installed versions. Read warnings rather than treating a successful launch as proof that every integration is ready.

## Credits

Inspired by [Teddy-bear-123](https://github.com/Teddy-bear-123), [chris@machine / Neovim from scratch](https://github.com/LunarVim/Neovim-from-scratch), [ThePrimeagen](https://www.youtube.com/watch?v=w7i4amO_zaE), and [GhilesLarbi](https://github.com/GhilesLarbi/NeovimDots).

Thanks to the Neovim community and the maintainers of the plugins and tools used here. Consult their upstream documentation and licenses for details about individual dependencies.
