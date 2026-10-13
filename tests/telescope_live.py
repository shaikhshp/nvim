#!/usr/bin/env python3
"""Exercise the unchanged Space-F mapping with installed modern Treesitter.

Run with the provider Python and pynvim. Isolated startup, synthetic buffers only;
no provider/model requests, plugin installs, or source-file writes.
"""

from pathlib import Path
import os
import signal
import subprocess
import sys
import tempfile
import threading
import time

import pynvim


def main():
    nvim, process, watchdog = None, None, None
    with tempfile.TemporaryDirectory(prefix="nvim-buffer-search-") as directory:
        socket = Path(directory) / "nvim.sock"

        def cleanup():
            if process is not None:
                for sig in (signal.SIGTERM, signal.SIGKILL):
                    try:
                        os.killpg(process.pid, sig)
                    except ProcessLookupError:
                        pass
                    try:
                        process.wait(timeout=3)
                        return
                    except subprocess.TimeoutExpired:
                        pass
                raise RuntimeError("Owned test process did not terminate")

        try:
            process = subprocess.Popen([
                "nvim", "--headless", "-u", "NONE", "-i", "NONE", "--noplugin", "--listen", str(socket),
            ], stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
            watchdog = threading.Timer(45, cleanup)
            watchdog.daemon = True
            watchdog.start()
            deadline = time.monotonic() + 5
            while not socket.exists() and process.poll() is None and time.monotonic() < deadline:
                time.sleep(0.02)
            if not socket.exists():
                raise RuntimeError("Owned Neovim did not create its RPC socket")
            nvim = pynvim.attach("socket", path=str(socket))
            data = Path(nvim.exec_lua('return vim.fn.stdpath("data")')) / "lazy"
            for plugin in ("plenary.nvim", "telescope.nvim", "nvim-treesitter"):
                if not (data / plugin).is_dir():
                    raise RuntimeError("Install declared plugins before live checks: " + plugin)
            nvim.ui_attach(120, 40, rgb=True)
            nvim.exec_lua(
                'local root, plugins = ...; vim.o.packpath = ""; vim.opt.runtimepath:prepend(root); '
                'for _, plugin in ipairs({"plenary.nvim", "telescope.nvim", "nvim-treesitter"}) do '
                'vim.opt.runtimepath:prepend(plugins .. "/" .. plugin) end; '
                'require("user.keymaps"); require("user.telescope"); vim.cmd("runtime plugin/telescope.lua"); '
                'assert(debug.getinfo(require("telescope").setup).source:find("/lazy/telescope.nvim/", 1, true)); '
                'assert(vim.fn.maparg(" F", "n") == "<Cmd>Telescope current_buffer_fuzzy_find<CR>" '
                'or vim.fn.maparg(" F", "n", false, true).rhs == "<cmd>Telescope current_buffer_fuzzy_find<CR>"); '
                'assert(require("nvim-treesitter.parsers").ft_to_lang == nil, "Regression needs modern parser API"); '
                'assert(vim.treesitter.language.add("lua") and vim.treesitter.query.get("lua", "highlights"), '
                '"Install the declared Lua parser before the parser-backed live check"); '
                'assert(not vim.treesitter.language.add("unconfigured_fixture"), "Fallback fixture unexpectedly has a parser")',
                str(Path.cwd()), str(data),
            )

            def wait(code, message):
                deadline = time.monotonic() + 5
                while time.monotonic() < deadline:
                    if nvim.exec_lua("return " + code):
                        return
                    time.sleep(0.02)
                raise AssertionError((message, nvim.exec_lua('return vim.fn.execute("messages")')))

            cases = [
                ("lua", "fixture with spaces.lua"),
                ("markdown", "fixture.md"),
                ("text", "fixture.txt"),
                ("unconfigured_fixture", "fixture.unknown"),
                ("", None),
            ]
            for ft, filename in cases:
                nvim.command("enew!")
                if filename:
                    nvim.api.buf_set_name(0, str(Path(directory) / filename))
                nvim.current.buffer.options["filetype"] = ft
                lines = ["-- synthetic search fixture", "local result = 'needle_823_marker'", "return result"]
                nvim.current.buffer[:] = lines
                buf, win = nvim.current.buffer.number, nvim.current.window.handle
                nvim.input(" F")
                wait('vim.bo.filetype == "TelescopePrompt"', "Space-F did not open")
                nvim.input("needle_823_marker")
                wait(
                    '(function() local s = require("telescope.actions.state"); '
                    'local p = s.get_current_picker(vim.api.nvim_get_current_buf()); '
                    'local e = s.get_selected_entry(); return p and p.manager:num_results() == 1 '
                    'and e and e.lnum == 2 end)()',
                    "Current-buffer search did not find the unique line",
                )
                nvim.input("<CR>")
                wait(
                    'vim.api.nvim_get_current_buf() == ' + str(buf)
                    + ' and vim.api.nvim_get_current_win() == ' + str(win)
                    + ' and vim.api.nvim_win_get_cursor(0)[1] == 2',
                    "Selection did not return to the correct source line",
                )
                assert list(nvim.current.buffer[:]) == lines and nvim.current.buffer.options["modified"]
                print("PASS: unchanged Space-F searches unsaved " + (ft or "unnamed") + " buffer and selects line", flush=True)
        finally:
            failed = sys.exc_info()[0] is not None
            if nvim is not None and process.poll() is None:
                try:
                    nvim.command("qa!")
                except Exception:
                    pass
            if watchdog is not None:
                watchdog.cancel()
                watchdog.join()
            try:
                cleanup()
            except Exception as error:
                if not failed:
                    raise
                print("Cleanup warning: " + str(error), file=sys.stderr)
            if process is not None and process.stdin:
                process.stdin.close()
            if nvim is not None:
                try:
                    nvim.close()
                except Exception:
                    pass
    print("PASS: modern Treesitter, no-parser fallback, unsaved buffer text, and source selection")


if __name__ == "__main__":
    main()
