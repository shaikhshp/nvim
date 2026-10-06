#!/usr/bin/env python3
"""Opt-in UI integration checks using installed plugins and disposable Git/files.

Run with the configured provider Python and pynvim. No plugin/tool installations,
model requests, user-source writes, or commits in the configuration repository.
"""

import os
import json
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
    if not shutil.which("git") or not shutil.which("diff"):
        raise RuntimeError("UI live checks require existing Git and diff executables")
    root = Path.cwd()
    data = Path(subprocess.check_output(
        ["nvim", "--headless", "-u", "NONE", "-i", "NONE",
         "+lua io.write(vim.fn.stdpath('data'))", "+qa!"], text=True,
    ).strip())
    for name in ("lazy.nvim", "aerial.nvim", "diffview.nvim", "undotree"):
        if not (data / "lazy" / name).is_dir():
            raise RuntimeError("Install the declared plugin explicitly before live checks: " + name)
    nvim = None
    watchdog = None
    with tempfile.TemporaryDirectory(prefix="nvim-ui-live-") as directory:
        project = Path(directory)
        source = project / "file with spaces.lua"
        other = project / "other.lua"
        notebook = project / "notebook.ipynb"
        nested = project / "nested"
        nested.mkdir()
        notebook_data = {
            "cells": [{"id": "fixture-cell", "cell_type": "code", "metadata": {},
                       "source": ["value = 1\n"], "execution_count": None, "outputs": []}],
            "metadata": {"language_info": {"name": "python"}},
            "nbformat": 4, "nbformat_minor": 5,
        }
        text = (
            "local function alpha()\n"
            "    local function nested()\n"
            "        return 1\n"
            "    end\n"
            "    return nested()\n"
            "end\n\n"
            "local function beta()\n"
            "    return 2\n"
            "end\n\n"
            "return alpha() + beta()\n"
        )
        env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
        env.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_SYSTEM=os.devnull)
        env.update(
            GIT_AUTHOR_NAME="UI Fixture", GIT_AUTHOR_EMAIL="ui@example.invalid",
            GIT_COMMITTER_NAME="UI Fixture", GIT_COMMITTER_EMAIL="ui@example.invalid",
        )

        def git(*args):
            return subprocess.check_output(["git", *args], cwd=project, env=env, text=True)

        git("init", "--initial-branch=main")
        source.write_text(text)
        other.write_text("local function gamma()\n    return 3\nend\nreturn gamma()\n")
        notebook.write_text(json.dumps(notebook_data))
        (nested / "nested.ipynb").write_text(json.dumps(notebook_data))
        git("add", ".")
        git("commit", "-m", "Disposable UI fixture")
        source.write_text(text.replace("return 2", "return 4"))
        git("add", ".")
        git("commit", "-m", "Disposable history fixture")
        source.write_text(text.replace("return 2", "return 5"))
        notebook_data["cells"][0]["source"] = ["value = 2\n"]
        notebook.write_text(json.dumps(notebook_data))
        (nested / "nested.ipynb").write_text(json.dumps(notebook_data))
        disk = source.read_bytes()
        index = git("diff", "--cached")

        def lua(code, *args):
            return nvim.exec_lua(code, *args)

        def wait(condition, label):
            # Diffview defers API work while Neovim is locked by an RPC callback.
            deadline = time.monotonic() + 10
            while time.monotonic() < deadline:
                if lua("return " + condition):
                    return
                time.sleep(0.02)
            details = lua(
                'local v = require("diffview.lib").get_current_view(); return {'
                'messages=vim.fn.execute("messages"), ready=v and v.ready, '
                'updating=v and v.panel.updating, entries=v and #v.panel.entries, '
                'options=v and v.panel.log_options, source=vim.api.nvim_buf_get_name(0)}'
            )
            raise AssertionError((label, details))

        def mapped(key):
            assert lua('return next(vim.fn.maparg(..., "n", false, true)) ~= nil', key), key
            # Execute as normal user input, not inside a locked RPC callback.
            nvim.input(key)
            time.sleep(0.05)

        def windows():
            return lua(
                'local result = {}; for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do '
                'local b = vim.api.nvim_win_get_buf(w); if vim.api.nvim_win_get_config(w).relative == "" then '
                'table.insert(result, {id=w, buf=b, ft=vim.bo[b].filetype, pos=vim.api.nvim_win_get_position(w), '
                'width=vim.api.nvim_win_get_width(w), height=vim.api.nvim_win_get_height(w)}) end end; return result'
            )

        def panel(ft):
            return next((win for win in windows() if win["ft"] == ft), None)

        def stack():
            lua('require("user.sidebar").reconcile()')
            tree, outline = panel("NvimTree"), panel("aerial")
            assert tree and outline, windows()
            assert tree["pos"][1] == outline["pos"][1] == 0, windows()
            assert tree["width"] == outline["width"] == 30, windows()
            assert tree["pos"][0] < outline["pos"][0], windows()
            assert len([w for w in windows() if w["ft"] == "aerial"]) == 1
            return tree, outline

        def bottom():
            lua('require("user.undotree").resize()')
            layout = nvim.funcs.winlayout()
            undo = panel("undotree")
            assert undo and layout[0] == "col", windows()
            last = layout[1][-1]
            if last[0] == "leaf":
                assert last[1] == undo["id"] and undo["width"] == nvim.options["columns"], windows()
            else:
                assert last[0] == "row" and last[1][0] == ["leaf", undo["id"]], layout
                diff = panel("diff")
                assert diff and last[1][1] == ["leaf", diff["id"]], layout
                assert diff["pos"][0] == undo["pos"][0], windows()

        def passed(message):
            print("PASS: " + message, flush=True)

        try:
            nvim = pynvim.attach("child", argv=[
                "nvim", "--embed", "--headless", "-i", "NONE",
                "--cmd", "lua vim.opt.runtimepath:prepend(vim.fn.getcwd())",
                "-u", str(root / "init.lua"),
            ])
            child_pid = lua("return vim.fn.getpid()")
            watchdog = threading.Timer(60, lambda: os.kill(child_pid, signal.SIGTERM))
            watchdog.daemon = True
            watchdog.start()
            nvim.ui_attach(160, 55, rgb=True)
            lua(
                'require("persistence").stop(); for _, name in ipairs(require("user.lsp.mason").servers) do '
                'vim.lsp.enable(name, false) end; require("persistence.config").options.dir = ...; '
                'vim.fn.mkdir(..., "p")',
                str(project / "sessions") + "/",
            )
            nvim.command("cd " + nvim.funcs.fnameescape(str(project)))
            nvim.command("edit " + nvim.funcs.fnameescape(str(source)))
            editor = nvim.current.window.handle
            assert not panel("aerial") and not panel("undotree")
            mapped(" e")
            mapped(" ot")
            tree, outline = stack()
            assert nvim.current.window.handle == editor
            lua('require("aerial").sync_load()')
            wait(
                '(function() for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do '
                'local b = vim.api.nvim_win_get_buf(w); if vim.bo[b].filetype == "aerial" then '
                'return table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), "\\n"):find("nested", 1, true) ~= nil end end end)()',
                "Hierarchical Lua symbols missing",
            )
            passed("tree-first stack, source focus, actual hierarchical symbols")

            mapped(" ot")
            assert not panel("aerial")
            mapped(" e")
            assert not panel("NvimTree")
            mapped(" ot")
            assert panel("aerial") and panel("aerial")["width"] == 30
            assert lua('return require("bufferline.offset").get().left_size') == 31
            mapped(" e")
            tree, outline = stack()
            assert lua('return require("bufferline.offset").get().left_size') == 31
            passed("outline-first stack and single Bufferline offset")

            nvim.current.window = nvim.windows[[w.handle for w in nvim.windows].index(editor)]
            nvim.command("vsplit " + nvim.funcs.fnameescape(str(other)))
            second = nvim.current.window.handle
            lua('require("user.sidebar").reconcile()')
            _, outline = stack()
            assert lua('return vim.w[...].source_win', outline["id"]) == second
            nvim.api.set_current_win(tree["id"])
            mapped(" of")
            assert nvim.current.window.handle == panel("aerial")["id"]
            assert lua('return vim.w[...].source_win', panel("aerial")["id"]) == second
            nvim.api.set_current_win(editor)
            lua('require("user.sidebar").reconcile()')
            mapped(" on")
            assert nvim.current.window.handle == editor
            mapped(" op")
            passed("outline follows editor splits; focus/navigation from panels")

            nvim.api.set_current_win(editor)
            nvim.command("split")
            same_buffer = nvim.current.window.handle
            lua(
                'local first, second, tree = ...; vim.api.nvim_set_current_win(first); '
                'vim.api.nvim_set_current_win(second); vim.api.nvim_set_current_win(tree)',
                editor, same_buffer, panel("NvimTree")["id"],
            )
            wait(
                '(function() for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do '
                'if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "aerial" then '
                'return vim.w[w].source_win == ' + str(same_buffer) + ' end end end)()',
                "Rapid same-buffer focus followed by tree lost outline source",
            )
            nvim.api.win_close(same_buffer, True)
            passed("rapid same-buffer split focus retains the latest outline source")

            nvim.api.win_close(panel("aerial")["id"], True)
            assert not panel("aerial")
            mapped(" of")
            stack()
            nvim.api.win_close(panel("NvimTree")["id"], True)
            assert not panel("NvimTree") and panel("aerial")
            mapped(" e")
            stack()
            nvim.api.set_current_win(second)
            lua('require("user.sidebar").reconcile()')
            nvim.api.win_close(second, True)
            wait(
                '(function() for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do '
                'if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "aerial" then '
                'return vim.w[w].source_win == ' + str(editor) + ' end end end)()',
                "Outline retained a closed source window",
            )
            nvim.command("botright new")
            utility = nvim.current.window.handle
            lua('vim.bo.buftype = "nofile"; vim.bo.filetype = "qf"')
            mapped(" of")
            assert lua('return vim.w[...].source_win', panel("aerial")["id"]) == editor
            nvim.api.win_close(utility, True)
            nvim.ui_try_resize(40, 16)
            wait(
                '(function() for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do '
                'if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "aerial" then '
                'return vim.api.nvim_win_get_width(w) == 20 end end end)()',
                "Existing outline did not clamp on a narrow screen",
            )
            assert panel("NvimTree")["width"] == 20
            nvim.ui_try_resize(160, 55)
            wait(
                '(function() for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do '
                'if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "aerial" then '
                'return vim.api.nvim_win_get_width(w) == 30 end end end)()',
                "Sidebar width did not recover",
            )
            mapped(" ot")
            nvim.ui_try_resize(40, 12)
            mapped(" ot")
            assert not panel("aerial"), "Outline opened despite insufficient room"
            nvim.ui_try_resize(160, 55)
            mapped(" ot")
            stack()
            passed("raw panel closes, closed-source recovery, utility focus, and cramped-screen guard")

            nvim.command("tabnew " + nvim.funcs.fnameescape(str(other)))
            assert not panel("NvimTree") and not panel("aerial")
            mapped(" ot")
            assert panel("aerial") and not panel("NvimTree")
            nvim.command("tabclose")
            stack()
            lua('vim.o.columns = 120; vim.o.lines = 42; vim.api.nvim_exec_autocmds("VimResized", {})')
            stack()
            nvim.ui_try_resize(160, 55)
            passed("per-tab isolation and terminal resize preserve shared sidebar")

            nvim.api.set_current_win(editor)
            lua('vim.api.nvim_feedkeys(vim.keycode("Go-- state one<Esc>"), "xt", false)')
            sequence = nvim.funcs.undotree()["seq_cur"]
            saved_lines = list(nvim.current.buffer[:])
            lua('vim.api.nvim_feedkeys(vim.keycode("Go-- state two<Esc>"), "xt", false)')
            assert nvim.funcs.undotree()["seq_cur"] > sequence
            nvim.command("undo")
            lua('vim.api.nvim_feedkeys(vim.keycode("Go-- alternate state<Esc>"), "xt", false)')
            mapped(" Ut")
            bottom()
            assert nvim.current.buffer.options["filetype"] == "undotree"
            target = lua('return vim.fn.eval("t:undotree.Index2Screen(t:undotree.seq2index[" .. ... .. "])")', sequence)
            nvim.current.window.cursor = (target, 0)
            mapped("<CR>")
            assert list(nvim.buffers[lua('return vim.api.nvim_win_get_buf(...)', editor)][:]) == saved_lines
            assert source.read_bytes() == disk
            mapped("D")
            bottom()
            stack()
            mapped(" Ut")
            assert not panel("undotree")
            mapped(" e")
            mapped(" ot")
            nvim.api.set_current_win(editor)
            mapped(" Uf")
            bottom()
            mapped(" e")
            mapped(" ot")
            stack()
            bottom()
            mapped(" Ut")
            passed("bottom undo/diff row, undo node selection without writes, undo-first opening order")

            nvim.api.set_current_win(editor)
            original_tab = nvim.current.tabpage.handle
            tree, outline = stack()
            mapped(" gF")
            wait(
                '(function() local v = require("diffview.lib").get_current_view(); '
                'return vim.t.user_diffview == true and v and v.ready and v.cur_entry '
                'and v.cur_entry.opened and v.cur_layout:is_files_loaded() end)()',
                "Diffview revision content did not finish opening",
            )
            assert nvim.current.tabpage.handle != original_tab
            assert not panel("NvimTree") and not panel("aerial")
            mapped(" gE")
            assert nvim.current.buffer.options["filetype"] == "DiffviewFiles"
            assert lua('return require("bufferline.offset").get().left_size') == 31
            for key in ("s", "-", "S", "U", "X", " co", " ct", " cb", " ca"):
                assert not lua('return vim.fn.maparg(..., "n", false, true).buffer == 1', key), key
            mapped(" e")
            assert not panel("NvimTree")
            mapped(" gQ")
            assert nvim.current.tabpage.handle == original_tab
            assert stack()[0]["id"] == tree["id"] and panel("aerial")["id"] == outline["id"]
            passed("filename-safe Diffview review, safe panel controls, original sidebar retained")

            nvim.api.set_current_win(editor)
            mapped(" gh")
            wait(
                '(function() local v = require("diffview.lib").get_current_view(); '
                'return v and v.ready and not v.panel.updating and #v.panel.entries > 0 '
                'and v.cur_entry and v.cur_entry.opened and v.cur_layout:is_files_loaded() end)()',
                "File history did not finish loading",
            )
            assert panel("DiffviewFileHistory")
            mapped(" gQ")
            nvim.api.set_current_win(editor)
            mapped(" gH")
            wait(
                '(function() local v = require("diffview.lib").get_current_view(); '
                'return v and v.ready and not v.panel.updating and #v.panel.entries > 0 '
                'and v.cur_entry and v.cur_entry.opened and v.cur_layout:is_files_loaded() end)()',
                "Project history did not finish loading",
            )
            mapped(" gQ")
            assert git("diff", "--cached") == index and source.read_bytes() == disk
            passed("file/project history without index or source writes")

            nvim.api.set_current_win(editor)
            mapped(" gD")
            wait(
                '(function() local v = require("diffview.lib").get_current_view(); '
                'return v and v.ready and v.cur_entry and v.cur_entry.opened '
                'and v.cur_layout:is_files_loaded() end)()',
                "Project diff did not load",
            )
            paths = lua(
                'local paths = {}; for _, file in require("diffview.lib").get_current_view().files:iter() do '
                'table.insert(paths, file.path) end; return paths'
            )
            assert paths and not any(path.endswith(".ipynb") for path in paths), paths
            mapped(" gQ")
            nvim.api.set_current_win(editor)
            nvim.command("edit! " + nvim.funcs.fnameescape(str(notebook)))
            assert nvim.current.buffer.options["filetype"] == "python"
            tabs = len(nvim.tabpages)
            mapped(" gF")
            assert len(nvim.tabpages) == tabs and not lua('return vim.t.user_diffview == true')
            nvim.command("edit! " + nvim.funcs.fnameescape(str(source)))
            passed("root/nested notebook working-tree diffs excluded; converted notebook file review refused")

            nvim.api.set_current_win(editor)
            lua('require("persistence").save()')
            mapped(" ot")
            mapped(" e")
            lua('require("persistence").load()')
            wait('require("user.sidebar").source_window() ~= nil', "No source after session load")
            mapped(" e")
            mapped(" ot")
            stack()
            passed("session restore discards stale handles and supports reopening panels")
            nvim.api.set_current_win(lua('return require("user.sidebar").source_window()'))
            nvim.command("tabonly!")
            nvim.command("only!")
            mapped(" ot")
            last_source = lua('return require("user.sidebar").source_window()')
            nvim.api.win_close(last_source, True)
            wait(
                '#vim.api.nvim_list_wins() == 1 and vim.bo.buftype == "" and vim.bo.filetype ~= "aerial"',
                "Last-source closure left an orphaned outline",
            )
            assert nvim.current.buffer.name == "" and nvim.current.buffer.options["modifiable"]
            assert not lua('return vim.w.is_aerial_win == true')
            nvim.command("edit " + nvim.funcs.fnameescape(str(source)))
            mapped(" ot")
            assert panel("aerial")
            passed("last-source closure leaves a normal editor and supports reopening outline")
            assert (root / "lua/user/sidebar.lua").is_file()
        finally:
            failed = sys.exc_info()[0] is not None
            if nvim is not None:
                try:
                    nvim.command("qa!")
                except (EOFError, OSError):
                    pass
                except Exception:
                    if not failed:
                        raise
                finally:
                    if watchdog is not None:
                        watchdog.cancel()
                    nvim.close()
    print("PASS: disposable UI checks complete; fixture repository removed", flush=True)


if __name__ == "__main__":
    main()
