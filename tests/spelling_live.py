#!/usr/bin/env python3
"""Opt-in real spelling LSP checks; run with the configured provider Python.

Requires Linux (/proc), pynvim, Neovim 0.12+, installed mason.nvim/mason-lspconfig.nvim/
nvim-lspconfig, and Mason's harper-ls and typos-lsp binaries. No network,
installation, provisioning, full user startup, or provider restart. Only
synthetic temporary files are opened; reports contain synthetic diagnostics.
Workspace edits affect disposable buffers only, never their disk files.
Only explicit config/Lazy runtime roots are prepended; retained old Packer
packages are excluded by clearing packpath before any plugin require.
"""

import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time

import pynvim


def main():
    root = Path(__file__).resolve().parents[1]
    if not shutil.which("nvim"):
        raise RuntimeError("Requires installed Neovim")
    data = Path(subprocess.check_output(
        ["nvim", "--headless", "-u", "NONE", "-i", "NONE", "--noplugin",
         "+lua io.write(vim.fn.stdpath('data'))", "+qa!"], text=True, timeout=10,
    ).strip())
    plugins = [data / "lazy" / name for name in
               ("mason.nvim", "mason-lspconfig.nvim", "nvim-lspconfig")]
    for path in plugins:
        if not path.is_dir():
            raise RuntimeError("Requires installed plugin: " + path.name)
    for name in ("harper-ls", "typos-lsp"):
        binary = data / "mason" / "bin" / name
        if not os.access(binary, os.X_OK):
            raise RuntimeError("Requires installed Mason executable: " + name)
        receipt = json.loads((data / "mason" / "packages" / name / "mason-receipt.json").read_text())
        print("SERVER: " + name + " " + receipt["source"]["id"], flush=True)

    nvim = None
    process = None
    watchdog = None
    expired = threading.Event()
    with tempfile.TemporaryDirectory(prefix="nvim-spelling-live-") as directory:
        project = Path(directory)
        socket = project / "nvim.sock"
        env = dict(os.environ, XDG_STATE_HOME=str(project / "state"),
                   NVIM_LOG_FILE=str(project / "nvim.log"))

        def cleanup():
            # Popen creates an owned session: never signal unrelated editors/servers.
            if process is not None:
                try:
                    os.killpg(process.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    pass
                # A server can outlive its editor, including during failed startup.
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait(timeout=3)

        def timeout():
            expired.set()
            cleanup()

        def lua(code, *args):
            return nvim.exec_lua(code, *args)

        def wait(condition, label, seconds=15):
            deadline = time.monotonic() + seconds
            while time.monotonic() < deadline:
                if lua("return " + condition):
                    return
                time.sleep(0.05)
            raise AssertionError("Timed out: " + label)

        def passed(label):
            print("PASS: " + label, flush=True)

        def clients():
            result = lua("""
                local result = {}
                for _, c in ipairs(vim.lsp.get_clients()) do
                    result[#result + 1] = {name=c.name, id=c.id,
                        root=c.config.root_dir, stopped=c:is_stopped()}
                end
                return result
            """)
            children = Path(f"/proc/{process.pid}/task/{process.pid}/children").read_text().split()
            executables = {Path(f"/proc/{pid}/exe").resolve().name for pid in children}
            for client in result:
                assert client["name"] in ("harper_ls", "typos_lsp"), result
                binary = {"harper_ls": "harper-ls", "typos_lsp": "typos-lsp"}[client["name"]]
                assert binary in executables and not client["stopped"], (result, executables)
            assert not lua('return vim.lsp.is_enabled("grammarly")')
            return result

        def open_fixture(name, ft, text, server=None, expected_lines=()):
            path = project / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
            nvim.command("edit! " + nvim.funcs.fnameescape(str(path)))
            nvim.current.buffer.options["filetype"] = ft
            if server:
                wait('(#vim.lsp.get_clients({bufnr=0, name=' + json.dumps(server) + '}) == 1)',
                     name + " attach")
                clients()
                attached = lua('local r = {}; for _, c in ipairs(vim.lsp.get_clients({bufnr=0})) do '
                               'r[#r+1] = c.name end; return r')
                assert attached == [server], (name, attached)
                wait("(function() local lines = {}; for _, d in ipairs(vim.diagnostic.get(0)) do "
                     "lines[d.lnum] = true end; for _, line in ipairs(" +
                     "{" + ",".join(map(str, expected_lines)) + "}" +
                     ") do if not lines[line] then return false end end; return true end)()",
                     name + " diagnostic lines")
                # Allow the complete publication, not just its first diagnostic.
                time.sleep(0.2)
                diagnostics = lua("return vim.diagnostic.get(0)")
                assert diagnostics and all(d["severity"] == 4 for d in diagnostics), (name, diagnostics)
                lua("""
                    for _, c in ipairs(vim.lsp.get_clients({bufnr=0})) do
                        for _, pull in ipairs({false, true}) do
                            local opts = vim.diagnostic.config(nil, vim.lsp.diagnostic.get_namespace(c.id, pull))
                            assert(opts.signs == false and opts.virtual_text == false and opts.update_in_insert == false)
                        end
                    end
                    assert(vim.deep_equal(vim.diagnostic.config(), _G.spelling_live_global))
                    assert(vim.deep_equal(vim.diagnostic.config(nil, _G.spelling_live_compiler), _G.spelling_live_options))
                    if _G.spelling_live_compiler_buf then
                        local errors = vim.diagnostic.get(_G.spelling_live_compiler_buf, {namespace=_G.spelling_live_compiler})
                        assert(#errors == 1 and errors[1].severity == 1 and errors[1].message == "Synthetic compiler error")
                    end
                """)
                roots = [c["root"] for c in clients() if c["name"] == server]
                assert str(path.parent) in roots, (name, roots)
                passed(name + ": " + server + " HINT diagnostics and isolated rendering")
                return path, diagnostics
            time.sleep(0.3)
            assert lua("return #vim.lsp.get_clients({bufnr=0})") == 0, name
            assert not lua('return require("user.spelling").eligible(0)'), name
            passed(name + ": no spelling client")
            return path, []

        def quickfix(server, apply=False):
            clients()
            result = lua("""
                local name, apply = ...
                local c = assert(vim.lsp.get_clients({bufnr=0, name=name})[1])
                local ns = vim.lsp.diagnostic.get_namespace(c.id, false)
                local d = assert(vim.diagnostic.get(0, {namespace=ns})[1])
                local raw = assert(d.user_data.lsp)
                local params = {textDocument=vim.lsp.util.make_text_document_params(0),
                    range=raw.range, context={diagnostics={raw}, only={"quickfix"}}}
                local response, err = c:request_sync("textDocument/codeAction", params, 10000, 0)
                assert(response and not response.err, vim.inspect(err or response))
                local actions = response.result or {}
                assert(#actions > 0, "No quick fixes")
                if apply then
                    local edit
                    for _, action in ipairs(actions) do
                        if action.edit then edit = action.edit; break end
                    end
                    assert(edit, "No editable quick fix")
                    vim.lsp.util.apply_workspace_edit(edit, c.offset_encoding)
                end
                return #actions
            """, server, apply)
            clients()
            passed(server + ": native codeAction request returned " + str(result) + " quick fixes")

        try:
            process = subprocess.Popen(
                ["nvim", "--headless", "--embed", "--listen", str(socket),
                 "-u", "NONE", "-i", "NONE", "--noplugin"],
                stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                env=env, start_new_session=True,
            )
            watchdog = threading.Timer(120, timeout)
            watchdog.daemon = True
            watchdog.start()
            deadline = time.monotonic() + 10
            while not socket.exists():
                if process.poll() is not None or time.monotonic() > deadline:
                    raise RuntimeError("Isolated Neovim failed to start")
                time.sleep(0.02)
            nvim = pynvim.attach("socket", path=str(socket))
            lua("""
                local paths = ...
                vim.o.packpath = ""
                for i = #paths, 1, -1 do vim.opt.runtimepath:prepend(paths[i]) end
                local function assert_source(fn, expected)
                    local source = debug.getinfo(fn, "S").source
                    assert(source:sub(1, 1) == "@", source)
                    assert(vim.uv.fs_realpath(source:sub(2)) == vim.uv.fs_realpath(expected), source)
                end
                assert_source(require("mason").setup, paths[2] .. "/lua/mason/init.lua")
                assert_source(require("mason-lspconfig").setup, paths[3] .. "/lua/mason-lspconfig/init.lua")
                for _, name in ipairs({"harper_ls", "typos_lsp"}) do
                    local first = vim.api.nvim_get_runtime_file("lsp/" .. name .. ".lua", false)[1]
                    local expected = paths[4] .. "/lsp/" .. name .. ".lua"
                    assert(first and vim.uv.fs_realpath(first) == vim.uv.fs_realpath(expected), first or name)
                end
                -- New Mason refreshes registries during setup, even with no installs.
                require("mason.settings").set({registry_cache={refresh=false}})
                vim.lsp.set_log_level("OFF")
                require("user.lsp.handlers").setup()
                _G.spelling_live_global = vim.deepcopy(vim.diagnostic.config())
                _G.spelling_live_compiler = vim.api.nvim_create_namespace("SyntheticCompiler")
                vim.diagnostic.config({signs=true, virtual_text=true, update_in_insert=true}, _G.spelling_live_compiler)
                _G.spelling_live_options = vim.deepcopy(vim.diagnostic.config(nil, _G.spelling_live_compiler))
                require("user.lsp.mason")
                for name in pairs(vim.lsp._enabled_configs) do
                    if name ~= "harper_ls" and name ~= "typos_lsp" then vim.lsp.enable(name, false) end
                end
                assert(vim.lsp.is_enabled("harper_ls") and vim.lsp.is_enabled("typos_lsp"))
                assert(vim.o.packpath == "" and not require("mason.settings").current.registry_cache.refresh)
            """, [str(root), *map(str, plugins)])
            passed("Mason/mason-lspconfig module sources and first native LSP definitions use Lazy roots; old packages excluded")
            nvim.command("cd " + nvim.funcs.fnameescape(str(project)))

            prose = "This sentence contains a mispelled word.\n"
            path, _ = open_fixture("standalone/note.txt", "text", prose, "harper_ls", (0,))
            disk = path.read_bytes()
            before = list(nvim.current.buffer[:])
            quickfix("harper_ls", apply=True)
            assert list(nvim.current.buffer[:]) != before
            assert path.read_bytes() == disk and nvim.current.buffer.options["modified"]
            passed("Harper workspace edit changes only the synthetic buffer, not disk")
            markdown = (prose + "\n```python\nmispelled = 1\n```\n\n"
                        "~~~text\nmispelled\n~~~\n\nInline code: `mispelled`.\n")
            _, diagnostics = open_fixture("prose/note.md", "markdown", markdown, "harper_ls", (0,))
            assert all(d["lnum"] == 0 for d in diagnostics), diagnostics
            passed("Markdown backtick/tilde fences and inline code are skipped")
            for name, ft, text in (
                ("plain.tex", "plaintex", prose),
                ("document.tex", "tex", "\\documentclass{article}\n\\begin{document}\n" + prose + "\\end{document}\n"),
                ("page.html", "html", "<html><body><p>" + prose.strip() + "</p></body></html>\n"),
                ("document.typ", "typst", prose),
                ("document.qmd", "quarto", prose),
            ):
                line = 2 if ft == "tex" else 0
                open_fixture("prose/" + name, ft, text, "harper_ls", (line,))

            for name, ft, text, lines in (
                ("source.py", "python", '# A mispelled comment.\nmessage = "mispelled"\nmispelled_value = 1\n', (0, 1, 2)),
                ("source.js", "javascript", '// A mispelled comment.\nconst mispelled = "mispelled";\n', (0, 1)),
                ("source.rs", "rust", '// A mispelled comment.\nlet mispelled = "mispelled";\n', (0, 1)),
                ("data.json", "json", '{"mispelled": "mispelled"}\n', (0,)),
                ("references.bib", "bib", '@article{fixture,\n title = {A mispelled title},\n}\n', (1,)),
            ):
                open_fixture("code/" + name, ft, text, "typos_lsp", lines)
                if ft == "python":
                    quickfix("typos_lsp")
                    lua("""
                        _G.spelling_live_compiler_buf = vim.api.nvim_get_current_buf()
                        vim.diagnostic.set(_G.spelling_live_compiler, 0,
                            {{lnum=0, col=0, message="Synthetic compiler error", severity=1}})
                        assert(vim.diagnostic.get(0, {namespace=_G.spelling_live_compiler})[1].severity == 1)
                    """)
                    passed("compiler ERROR remains independent of spelling HINTs")

            custom = project / "custom"
            custom.mkdir()
            (custom / ".typos.toml").write_text('[default.extend-words]\nmispelled = "mispelled"\n')
            _, diagnostics = open_fixture("custom/source.py", "python",
                                          '# mispelled and teh\n', "typos_lsp", (0,))
            assert all(d["col"] >= len("# mispelled and ") for d in diagnostics), diagnostics
            passed("Typos discovers project .typos.toml: accepted token skipped, known typo still reported")

            notebook = project / "excluded/notebook.ipynb"
            open_fixture("excluded/notebook.ipynb", "json", '{"mispelled": "mispelled"}\n')
            nvim.current.buffer[:] = ['# mispelled displayed Python', 'mispelled = "mispelled"']
            nvim.current.buffer.options["filetype"] = "python"
            time.sleep(0.3)
            assert lua("return #vim.lsp.get_clients({bufnr=0})") == 0
            passed("displayed Python in .ipynb remains excluded")
            alias = notebook.parent / "alias.py"
            alias.symlink_to(notebook)
            nvim.command("edit! " + nvim.funcs.fnameescape(str(alias)))
            nvim.current.buffer.options["filetype"] = "python"
            time.sleep(0.3)
            assert not lua('return require("user.spelling").eligible(0)')
            assert lua("return #vim.lsp.get_clients({bufnr=0})") == 0
            passed("resolved .ipynb symlink is excluded")
            for ft in ("python", "markdown"):
                nvim.command("enew!")
                lua('vim.bo.buftype = "nofile"; vim.api.nvim_buf_set_name(0, ...)', str(project / ("scratch." + ft)))
                nvim.current.buffer[:] = ["A mispelled sentence."]
                nvim.current.buffer.options["filetype"] = ft
                time.sleep(0.3)
                assert lua("return #vim.lsp.get_clients({bufnr=0})") == 0
                assert not lua('return require("user.spelling").eligible(0)')
            passed("nofile Python/prose utility buffers have no spelling clients")
            clients()
            passed("all owned servers alive at end; Grammarly never enabled or attached")
            lua('assert(not package.loaded["user.ai"] and not package.loaded["cord"] '
                'and not package.loaded["persistence"] and not package.loaded["lazy"])')
            print("LIMITS: synthetic samples only; Typos checks known misspellings, not arbitrary unknown words. "
                  "The 1 MiB boundary is covered by tests/spelling_config.lua; no dictionaries were changed.", flush=True)
        finally:
            failed = sys.exc_info()[0] is not None
            if watchdog:
                watchdog.cancel()
                watchdog.join()
            if nvim is not None and process.poll() is None:
                try:
                    lua('vim.lsp.stop_client(vim.lsp.get_clients(), true); '
                        'vim.wait(3000, function() return #vim.lsp.get_clients() == 0 end, 20)')
                    nvim.command("qa!")
                except Exception:
                    pass
            try:
                cleanup()
            except Exception as error:
                if not failed:
                    raise
                print("Cleanup warning: " + str(error), file=sys.stderr, flush=True)
            if process is not None and process.stdin:
                process.stdin.close()
            if nvim is not None:
                try:
                    nvim.close()
                except Exception:
                    pass
            if expired.is_set():
                print("Watchdog terminated owned processes after 120 seconds", flush=True)


if __name__ == "__main__":
    main()
