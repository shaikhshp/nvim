# Neovim Configuration

A personal, modular Lua configuration for programming, technical writing, and notebooks. It combines native Neovim LSP, completion and snippets, explicit tool provisioning, formatting, debugging, fuzzy navigation, VimTeX, Jupyter integration, and on-demand local AI.

This is a configuration to read and adapt, not a general-purpose Neovim distribution. It uses **Packer**, targets **Neovim 0.12+**, and assumes a Linux-oriented development environment. Language tools, kernels, TeX utilities, and Ollama are separate dependencies; installing plugins alone does not install a complete development environment.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Everyday Use](#everyday-use)
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

| Area | Configuration |
| --- | --- |
| Appearance | Catppuccin Mocha, Bufferline, Lualine, indentation guides, file icons, color highlighting, and an Alpha dashboard |
| Navigation | Telescope file/text/buffer/project searches, NvimTree, and project.nvim |
| Editing | Treesitter, automatic pairs and tags, context-aware comments, and reference highlighting |
| Completion | nvim-cmp, LuaSnip, friendly-snippets, and LSP/buffer/path sources |
| Language services | Native LSP configuration with Mason-managed tools and language-specific overrides |
| Formatting | Conform, external-formatter preference, selected LSP fallback, and buffer/global save-format toggles |
| Debugging | nvim-dap and DAP UI, with Python, Rust, and Java integration |
| Git and terminals | Gitsigns, Telescope Git pickers, ToggleTerm, and a Lazygit terminal |
| Documents | VimTeX with latexmk/zathura, Glow, and browser-based Markdown preview |
| Notebooks | Jupytext percent-cell editing and explicit Molten kernel execution |
| Local AI | Ollama-backed reviews, explanations, correction previews, CodeCompanion chat, and manual Minuet completion |
| Other integrations | Discord Rich Presence through Cord, LeetCode, and vim-be-good |

The editor defaults to four-space indentation, absolute and relative line numbers, wrapping, mouse support, splits below/right, persistent undo, and system clipboard integration. Swap files and backup/writebackup files are disabled. The terminal font must be configured separately; a Nerd Font is recommended for icons.

The default colorscheme is `catppuccin-mocha`. Lualine uses a customized `iceberg_dark` theme. Tokyo Night, Darkplus, Rose Pine, and Ayu are also declared in the plugin specification.

Both **leader and localleader are Space**. See [KEYMAPS.md](KEYMAPS.md) for the detailed mapping catalog, including modes, buffer-local mappings, and plugin defaults.

## Requirements

### Core Dependencies

| Dependency | Purpose |
| --- | --- |
| Neovim 0.12+ | Modern native LSP and Treesitter APIs used by this configuration |
| Git | Plugin-manager bootstrap and plugin installation |
| `curl`, `tar`, and a C compiler | Treesitter parser downloads and builds |
| Tree-sitter CLI 0.26.1+ | Modern Treesitter parser installation; verify the installed plugin's current requirements |
| `ripgrep` (`rg`) | Telescope text search |
| Node.js and npm | Node-based language tools and the Markdown preview build |
| Clipboard provider | Access to the system clipboard through `unnamedplus` |
| Nerd Font | Recommended for UI icons |

`fd` is an optional file-search improvement. Python 3.10+ with venv/pip support is recommended for the notebook provider and Python test scripts.

Use a suitable [Neovim release or nightly](https://github.com/neovim/neovim/releases), rather than assuming your distribution package is recent enough. Some plugins are unpinned and can raise their minimum requirements; check the installed versions, especially Treesitter and VimTeX. The current VimTeX upstream documentation specifies Neovim 0.12.4.

Check `tree-sitter --version` before installing parsers. Prefer the installation methods recommended by [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter), rather than an npm-based CLI installation. Mason can provision `tree-sitter-cli`, but its available version still needs checking.

### Feature Dependencies

| Feature | Additional dependencies |
| --- | --- |
| Python | Project Python environment; Pyright/Ruff; Mason debugpy for debugging |
| Rust | Rust/Cargo, Clippy, rustfmt; rust-analyzer; Mason codelldb for debugging |
| Java | Compatible full JDK with `javac`; jdtls; Java debug/test bundles for those features |
| LaTeX | TeX distribution, latexmk, zathura, ChkTeX, latexindent and its Perl dependencies; texcount for counting commands |
| Markdown terminal preview | Glow executable |
| Notebooks | Isolated Python provider, Jupytext, Jupyter dependencies, and registered kernels |
| Local AI | curl, user-managed Ollama server, and an installed approved coder model |
| Named terminals | `lazygit`, `node`, `ncdu`, `htop`, or `python`, depending on the terminal used |

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

`lua/user/plugins.lua` bootstraps Packer if it is missing. **The first bootstrap clones Packer and requests a plugin sync**, so first startup can use the network.

Inside Neovim, install missing plugins and regenerate the loader:

```vim
:PackerInstall
:PackerCompile
:PackerStatus
```

Wait for installation/build operations to finish, then restart Neovim. Markdown browser preview runs an npm installation hook. Molten's remote-plugin registration needs the Python provider described in [Notebooks](#notebooks); repeat registration after setting up that provider.

The authoritative plugin specification is `lua/user/plugins.lua`. Some plugins are pinned; others follow upstream. This is not a fully locked dependency snapshot. `plugin/packer_compiled.lua` is generated locally and is intentionally not version-controlled.

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

| Mapping | Action |
| --- | --- |
| `<leader>a` | Dashboard |
| `<leader>e` | File explorer |
| `<leader>f` | Find files |
| `<leader>F` | Search current buffer |
| `<leader>b` | Buffer picker |
| `<leader>P` | Project picker |
| `<leader>sg` | Live grep |
| `<leader>w` / `<leader>q` | Write / quit current window |
| `<leader>c` | Close buffer with Bdelete |
| `<C-h/j/k/l>` | Move between windows |
| `H` / `L` | Previous / next buffer |
| `jk` / `kj` in Insert mode | Return to Normal mode |
| `<leader>gg` | Lazygit terminal |
| `<leader>gp` / `<leader>gs` | Preview / stage Git hunk |
| `<leader>tf`, `th`, `tv` | Floating, horizontal, vertical terminal |
| `<C-\>` | Toggle terminal |

**Git actions can change your worktree.** `<leader>gr` resets a hunk and `<leader>gR` resets buffer changes. Telescope Git pickers include checkout and other modifying actions; consult the catalog before treating them as read-only previews.

Completion uses `<C-j>`/`<C-k>` for selection, `<C-Space>` to request completion, and `<C-e>` to abort. Enter confirms an explicitly selected item. Tab/Shift-Tab navigate completion and snippets. Autopairs fast wrap uses `<M-e>` (Alt-e).

## Language Support

Native Neovim LSP is the active language-service stack. Configuration uses `vim.lsp.config()` and `vim.lsp.enable()`, with nvim-lspconfig server definitions and overrides in `lua/user/lsp/settings/`.

| Language / files | Configured server |
| --- | --- |
| Lua | `lua_ls` |
| Python | `pyright`, `ruff` |
| Rust | `rust_analyzer` |
| Java | `jdtls`, started separately |
| JavaScript / TypeScript | `ts_ls`, `eslint` |
| HTML / CSS | `html`, `cssls` |
| JSON | `jsonls` |
| Shell | `bashls` |
| C / C++ | `clangd` |
| Markdown | `marksman` |
| TeX / BibTeX | `texlab` |
| Writing assistance | `grammarly` |

Configured does not mean installed or attached. Only available configured executable commands are enabled. Check `:LspInfo`, `:Mason`, and `:checkhealth` when a feature is missing.

### Common LSP Mappings

| Mapping | Action |
| --- | --- |
| `gd` / `gD` | Definition / declaration |
| `gI` / `grr` | Implementation / references |
| `K` | Hover |
| `gl` | Diagnostic float |
| `<leader>la` / `<leader>lr` | Code action / rename |
| `<leader>lj` / `<leader>lk` | Next / previous diagnostic |
| `<leader>ld` / `<leader>lw` | Buffer / workspace diagnostic picker |
| `<leader>lf` | Format buffer |

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

| Filetype | External formatter policy |
| --- | --- |
| Python | Ruff format, then optional Black |
| JavaScript / TypeScript / React variants | prettierd, then Prettier |
| Rust | rustfmt |
| TeX / plain TeX / BibTeX | latexindent |
| Lua | StyLua |
| Shell | shfmt |
| JSON / JSONC / HTML / CSS / Markdown / YAML | Prettier |
| C / C++ | clang-format |

Ordered alternatives mean **the first available formatter**, not a chain of all listed tools. Inspect availability with `:ConformInfo`.

Formatting is synchronous with a **2000 ms timeout**. If no external formatter is available, one formatting-capable LSP client is selected, preferring Ruff for Python, rust-analyzer for Rust, jdtls for Java, and texlab for TeX/BibTeX; otherwise the lowest client ID wins. If Conform is missing, the helper attempts the selected LSP directly.

| Mapping / command | Effect |
| --- | --- |
| `<leader>lf` | Format manually |
| `<leader>lF` or `:FormatToggle` | Toggle save formatting for this buffer |
| `:FormatToggle!` | Toggle save formatting globally |

Either disable flag blocks format-on-save. Enabling one does not clear the other. Manual formatting ignores these save-disable flags but still respects buffer eligibility.

## Debugging

nvim-dap owns debugging, with DAP UI opening on launch/attach and closing on termination/exit. Install adapters explicitly with Mason; configuring a language server is not sufficient to debug it.

| Mapping | Action |
| --- | --- |
| `<leader>dd` | Continue / start |
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>di` / `<leader>do` / `<leader>dp` | Step into / out / over |
| `<leader>du` | Toggle DAP UI |

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

Markdown buffers enable wrapping and spellcheck. Use `:Glow` or `<leader>|` for terminal preview after installing Glow. Browser preview uses `:MarkdownPreview`; its plugin build hook runs `npm install` in the plugin's `app` directory. There are no extra custom browser-preview mappings.

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

Then restart. Repeat registration if the provider was missing during the plugin installation hook or its path changed. Inspect the actual paths with:

```vim
:lua print(require("user.python").host, require("user.python").jupytext)
```

The provider hosts Molten; the selected kernelspec determines where notebook code executes. For project-specific dependencies, install/register a kernel from that project's environment with a unique name rather than replacing the provider.

### Edit and Execute

Opening `.ipynb` displays Python in `py:percent` format. Jupytext uses `update = true` and `autosync = true`; saves update notebook JSON and synchronize existing pairs. A provider-backed YAML parser handles list-valued metadata. If dependencies are missing, notebooks can remain raw JSON; fix the setup and restart before editing them as code.

Mappings are buffer-local to `.ipynb`. Ordinary scripts opt in with `:NotebookEnable`. Neither opening a notebook nor enabling mappings starts a kernel or evaluates code.

| Mapping | Action |
| --- | --- |
| `<leader>mi` | Initialize and select a registered kernel |
| `<leader>me{motion}` | Evaluate motion |
| `<leader>ml` | Evaluate line |
| Visual `<leader>mv` | Evaluate selection |
| `<leader>mc` | Reevaluate an existing Molten region |
| `<leader>mo` | Show/enter active output window |
| `<leader>mq` | Hide output window |
| `<leader>md` | Delete Molten cell state, not source text |
| `<leader>mx` | Interrupt execution |

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

| Tag | Notes |
| --- | --- |
| `qwen2.5-coder:3b` | Default |
| `qwen2.5-coder:7b` | Larger alternative |
| `qwen2.5-coder:3b-8k` | Must already exist locally to select |
| `qwen2.5-coder:7b-16k` | Must already exist locally to select |

Unknown, shorthand, uninstalled, and remote-metadata-marked tags are rejected without automatic fallback. `:AIModel` or `<leader>Am` opens the picker; `:AIModel qwen2.5-coder:7b` selects explicitly. Selection is session-local, shared by review/completion, and cancels previous work.

Review and Minuet force `num_ctx = 4096` for every allowed tag. Chat defaults to the selected model and 4096 context, but exposes editable model/context settings; **that chat context default is not transport-enforced**. Larger-looking tag names do not enlarge review/completion context.

Loopback Ollama can itself host cloud-backed models. This integration checks the allowlist and excludes inventory entries with remote metadata, but that is not a general privacy guarantee. Where supported, configure `OLLAMA_NO_CLOUD=1` in the **Ollama server's environment** for additional protection. Service changes are your responsibility.

### Actions and Scope

| Mapping / command | Action |
| --- | --- |
| Normal/Visual `<leader>Ac` | Open chat with explicit context, initially unsent |
| Normal/Visual `<leader>Ae` | Explain scope/diagnostics in a scratch window |
| Normal/Visual `<leader>Ar` | Review scope |
| Normal `<leader>Ab` | Review eligible buffer |
| Normal/Visual `<leader>Af` | Propose correction in scratch diffs |
| `<leader>Ad` | Cancel and clear current-buffer AI hints |
| `<leader>Ax` | Cancel pending work without clearing existing hints |
| `:AIToggle` | Toggle current-buffer AI eligibility |
| `:AIContext file` / `:AIContext!` | Attach project-file snapshot / clear attachments |

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

| Mapping | Action |
| --- | --- |
| `<M-y>` | Request / next suggestion |
| `<M-]>` / `<M-[>` | Next / previous suggestion; request if none is visible |
| `<M-CR>` | Accept suggestion |
| `<M-l>` | Accept one line |
| `<M-x>` | Dismiss/cancel completion |

`<M-...>` means Alt/Meta and depends on terminal key handling. `<M-e>` remains Autopairs fast wrap, and cmp retains its own `<C-e>` and Tab behavior. Completion checks origin buffer/window/cursor, changedtick, and Insert mode. Cancelling a client request does not guarantee immediate server-side model-resource release.

## Network and Privacy

Local AI transport does **not** make the entire configuration offline or private:

- Packer bootstrap, plugin builds, Mason, and parser installation use the network.
- JSON language-service schemas can refer to remote URLs.
- Grammarly is configured when its executable is available; review that service separately.
- Cord is set up during startup when installed and can publish Discord Rich Presence. It is not gated behind an explicit command; review or disable it before using sensitive projects.
- LeetCode has account/network behavior and logging, with storage under `stdpath("data")/leetcode`.
- Notebook kernels and TeX shell escape execute code and should only be used with trusted inputs.

Review `lua/user/workflow.lua`, the plugin specification, and enabled language services before adopting the configuration. Avoid sharing local test reports or generated files without inspecting them for paths, process information, and content.

## Customization

### Repository Layout

```text
init.lua                   Startup orchestration and module load order
lua/user/
  options.lua              Editor defaults
  keymaps.lua              Global mappings
  plugins.lua              Packer declarations and pins
  formatting.lua           Manual/save formatting policy
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
KEYMAPS.md                 Detailed mapping catalog
AGENTS.md                  Repository maintenance guidance for coding agents
.stylua.toml               Lua formatting conventions
```

Options and the Python provider load first; VimTeX globals load before plugins. Completion, formatting, LSP, UI/navigation, documents/notebooks, debugging, and workflow setup follow. Java starts from its ftplugin.

Keep new feature setup under `lua/user/` and require startup modules from `init.lua`; keep the entrypoint focused on orchestration. Edit the appropriate owning module rather than adding a second setup call elsewhere.

Common customization locations:

| Change | File |
| --- | --- |
| Theme | `lua/user/colorscheme.lua` |
| Editor options | `lua/user/options.lua` |
| Global mappings | `lua/user/keymaps.lua` |
| Which-key group labels | `lua/user/whichkey.lua` |
| Plugins and versions | `lua/user/plugins.lua` |
| Server-specific settings | `lua/user/lsp/settings/` |
| Formatters and policy | `lua/user/formatting.lua` |
| Discord/LeetCode | `lua/user/workflow.lua` and plugin declarations |

Update [KEYMAPS.md](KEYMAPS.md) when changing mappings. Lua uses four-space indentation and double quotes, with formatting controlled by `.stylua.toml`.

## Maintenance

- `:PackerInstall` installs missing plugins; `:PackerCompile` regenerates the loader after specification changes.
- `:PackerSync` installs/updates and compiles. `:PackerUpdate` is also an update operation, not a harmless reload. Preserve deliberate version pins unless intentionally upgrading them.
- Packer uses `auto_clean = false`. Removed declarations do not remove old local packages; leftover start-packages can still load. Inspect obsolete installations separately.
- `:TSUpdate` updates parsers after Treesitter changes; it is also configured as the plugin's build hook.
- `<leader>r` sources the entrypoint but does **not** clear cached Lua modules. Restart after changes that need reinitialization.
- Keep generated loaders, Python caches, virtualenvs, logs, credentials, and live-test artifacts out of version control.

CodeCompanion is pinned to `v19.27.0`, Minuet to `3b0a4c5f97b7124d94302c608fbe01c0270d4fbe`, and Plenary to `74b06c6c75e4eeb3108ec01852001636d85a932b`. Check the full plugin specification for other pins. Copilot, CoC, null-ls, Magma, and impatient are not configured alternative stacks.

## Verification

There is no general build/CI pipeline. Focused checks live under `tests/`; run them from the repository root. A passing stubbed test does not prove that real servers, adapters, kernels, or model answers work correctly.

### Startup and Isolated Checks

```sh
nvim --headless '+quit'
nvim --headless -u NONE -i NONE -l tests/ai_config.lua
nvim --headless -u NONE -i NONE -l tests/formatting_config.lua
lua tests/notebook_config.lua
```

| Check | Coverage |
| --- | --- |
| Startup smoke | Loads the installed configuration; distinguish missing-plugin warnings from runtime errors |
| AI configuration | Synthetic/stubbed startup, eligibility/context/model guards, separate hints, stale callbacks, correction acceptance, and manual completion |
| Formatting configuration | Stubbed formatter ordering, LSP fallback, toggles, exclusions, and errors |
| Notebook configuration | Stubbed provider/plugin guards, settings, mapping scope, and explicit initialization |

The isolated AI test makes no real process/network requests. The startup smoke test is not an isolated first-install test: if Packer is missing, normal startup can bootstrap it.

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

Without `--model`, the harness benchmarks 3b and 7b and integrates the first. The option is repeatable. Tests send synthetic prompts only, do not pull models/provision dependencies/restart the daemon, and do not save source buffers. Retained reports contain synthetic prompts/responses and local process/resource information; inspect them before sharing.

Schema validation and integration success are not model-accuracy tests. Performance depends on hardware, cold loading, context, and competing jobs; no portable speed or memory guarantee is implied. Interactive LSP/DAP, Java bundles, TeX viewing, Markdown preview, and output export require separate checks with their real dependencies.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Missing icons or incorrect glyphs | Select a Nerd Font in your terminal; the GUI font option does not configure terminal fonts |
| Clipboard unavailable | `:checkhealth` and an installed clipboard provider appropriate to your session |
| Plugin feature missing | `:PackerStatus`, installation/build output, generated loader, and restart after installation |
| LSP not attached | `:LspInfo`, `:Mason`, executable availability, filetype, and project root |
| Treesitter highlighting missing | CLI/compiler versions, parser installation, and `:checkhealth`; CSS is deliberately excluded |
| Formatting not running | `:ConformInfo`, formatter/LSP availability, both save-disable flags, buffer size/type, and timeout |
| Java not attached | Recognized root, jdtls executable, compatible full JDK, `JAVA_HOME`, and launcher requirements |
| Debug launch fails | Adapter installation, target interpreter/toolchain, Java bundles, or Cargo build/artifact output |
| Notebook opens as JSON | Provider/Jupytext paths and executable availability; restart after correcting dependencies |
| Molten commands missing | Provider dependencies, `:UpdateRemotePlugins`, restart, and provider/Molten health checks |
| Notebook output absent or stale | Explicit kernel initialization/import; saving does not export live results, and retained results may be stale |
| AI unavailable | Local Ollama/curl availability, exact installed tag, eligibility/context limits, and buffer AI-disable flag |
| Alt completion keys not received | Terminal key encoding; verify Alt/Meta and Alt-Enter support |
| Removed plugin still active | Old local start-package directories; removing a declaration alone does not uninstall a package |

Useful health commands include `:checkhealth`, `:checkhealth provider`, and `:checkhealth molten` where supported by the installed versions. Read warnings rather than treating a successful launch as proof that every integration is ready.

## Credits

Inspired by [Teddy-bear-123](https://github.com/Teddy-bear-123), [chris@machine / Neovim from scratch](https://github.com/LunarVim/Neovim-from-scratch), [ThePrimeagen](https://www.youtube.com/watch?v=w7i4amO_zaE), and [GhilesLarbi](https://github.com/GhilesLarbi/NeovimDots).

Thanks to the Neovim community and the maintainers of the plugins and tools used here. Consult their upstream documentation and licenses for details about individual dependencies.
