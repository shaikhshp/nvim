#!/usr/bin/env python3
"""Run from the config root with the provider Python (requires pynvim).

Uses installed plugins and disposable fixture copies. No kernel execution unless
--kernel NAME is supplied; never exports Molten output or installs dependencies.
"""

import argparse
import copy
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

import pynvim


def check(path, expected):
    actual = json.loads(path.read_text())
    for key in ("nbformat", "nbformat_minor"):
        assert actual[key] == expected[key], key
    for key, value in expected["metadata"].items():
        if key == "jupytext":
            for name, setting in value.items():
                assert actual["metadata"][key][name] == setting, (key, name)
        else:
            assert actual["metadata"][key] == value, ("metadata", key)
    assert len(actual["cells"]) == len(expected["cells"]), "cell count"
    for index, (got, want) in enumerate(zip(actual["cells"], expected["cells"])):
        for key in ("id", "cell_type", "metadata"):
            assert got[key] == want[key], (index, key)
        assert "".join(got["source"]) == "".join(want["source"]), (
            index,
            "source/order",
        )
        if want["cell_type"] == "code":
            for key in ("outputs", "execution_count"):
                assert got[key] == want[key], (index, key)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--kernel", help="Explicitly execute fixture code with this installed kernel"
    )
    args = parser.parse_args()
    root = Path.cwd()
    fixture = root / "tests/notebook_roundtrip.ipynb"
    original_bytes = fixture.read_bytes()
    original = json.loads(original_bytes)
    nvim = None

    def passed(message):
        print("PASS: " + message, flush=True)

    def wait(condition, label):
        assert nvim.exec_lua(
            "return vim.wait(30000, function() return " + condition + " end, 50)"
        ), ("Timed out: " + label)

    def edit(path):
        nvim.command("edit! " + nvim.funcs.fnameescape(str(path)))

    def replace(old, new):
        lines = list(nvim.current.buffer[:])
        updated = [line.replace(old, new) for line in lines]
        assert updated != lines, "Missing buffer text: " + old
        nvim.current.buffer[:] = updated

    def write():
        nvim.current.buffer.options["modified"] = True
        nvim.command("write")
        wait("not vim.bo.modified and vim.g.notebook_live_jobs == 0", "async save/sync")

    def callback(key):
        nvim.exec_lua(
            'local m = vim.fn.maparg(..., "n", false, true); '
            'assert(type(m.callback) == "function", "Missing mapping"); m.callback()',
            "<Space>" + key,
        )

    def output_windows():
        return [
            win.handle
            for win in nvim.api.list_wins()
            if nvim.api.win_get_config(win)["relative"] != ""
            and nvim.api.get_option_value(
                "filetype", {"buf": nvim.api.win_get_buf(win)}
            )
            == "molten_output"
        ]

    with tempfile.TemporaryDirectory(prefix="notebook-live-") as directory:
        try:
            nvim = pynvim.attach(
                "child",
                argv=[
                    "nvim",
                    "--embed",
                    "--headless",
                    "-i",
                    "NONE",
                    "--cmd",
                    "lua vim.opt.rtp:prepend(" + json.dumps(str(root)) + ")",
                    "-u",
                    str(root / "init.lua"),
                ],
            )
            nvim.ui_attach(120, 40, rgb=True)
            wait(
                'vim.v.vim_did_enter == 1 and package.loaded["user.notebook"] ~= nil',
                "config startup",
            )
            # Track plugin subprocesses, including the paired sync after conversion.
            nvim.exec_lua("""
                local system = vim.system
                local executable = require("user.python").jupytext
                vim.g.notebook_live_jobs = 0
                vim.system = function(cmd, opts, on_exit)
                    if cmd[1] == executable and on_exit then
                        vim.g.notebook_live_jobs = vim.g.notebook_live_jobs + 1
                        return system(cmd, opts, function(result)
                            on_exit(result)
                            vim.g.notebook_live_jobs = vim.g.notebook_live_jobs - 1
                        end)
                    end
                    return system(cmd, opts, on_exit)
                end
            """)
            notebook = Path(directory) / "notebook.ipynb"
            shutil.copyfile(fixture, notebook)
            edit(notebook)
            assert nvim.current.buffer.name == str(notebook)
            assert nvim.current.buffer.options["filetype"] == "python"
            assert any(line.startswith("# %%") for line in nvim.current.buffer[:])
            assert (
                "#     - 3" in nvim.current.buffer[:]
            ), "Fixture YAML list was rewritten"
            assert nvim.current.buffer.vars["notebook_enabled"]
            assert not nvim.exec_lua(
                'return require("jupytext").get_option("async_write")'
            )
            write()
            check(notebook, original)
            passed(
                "original ipynb opens as percent Python; synchronous save preserves YAML lists, metadata, outputs, counts, IDs/order"
            )

            expected = copy.deepcopy(original)
            replace(
                "Keep cell order intact.", "Edited markdown; keep cell order intact."
            )
            expected["cells"][0]["source"][
                1
            ] = "Edited markdown; keep cell order intact."
            write()
            check(notebook, expected)
            edit(notebook)
            assert any("Edited markdown;" in line for line in nvim.current.buffer[:])
            passed("markdown edit/save/reopen preserves existing notebook data")
            replace("6 * 7", "6 * 9")
            expected["cells"][2]["source"] = ["6 * 9"]
            write()
            check(notebook, expected)
            passed(
                "code edit preserves old output 42/count 8 (stale, not a valid result for 6 * 9)"
            )

            paired = Path(directory) / "paired.ipynb"
            shutil.copyfile(fixture, paired)
            executable = nvim.exec_lua('return require("user.python").jupytext')
            subprocess.run(
                [executable, "--set-formats", "ipynb,py:percent", str(paired)],
                check=True,
                capture_output=True,
                text=True,
                timeout=30,
            )
            paired_expected = json.loads(paired.read_text())
            script = paired.with_suffix(".py")
            edit(paired)
            replace(
                "Keep cell order intact.",
                "Notebook paired edit; keep cell order intact.",
            )
            paired_expected["cells"][0]["source"][
                1
            ] = "Notebook paired edit; keep cell order intact."
            write()
            assert "Notebook paired edit;" in script.read_text()
            check(paired, paired_expected)
            passed(
                "Neovim ipynb save syncs paired script with outputs/counts/metadata/order preserved"
            )
            edit(script)
            # Isolate pairing from intentional Python format-on-save changes.
            nvim.current.buffer.vars["disable_autoformat"] = True
            replace("Notebook paired edit;", "Script paired edit;")
            paired_expected["cells"][0]["source"][
                1
            ] = "Script paired edit; keep cell order intact."
            write()
            check(paired, paired_expected)
            edit(paired)
            assert any("Script paired edit;" in line for line in nvim.current.buffer[:])
            passed(
                "Neovim async paired Python save syncs JSON and reopens correctly (buffer formatting disabled)"
            )

            if args.kernel:
                edit(notebook)
                assert (
                    args.kernel in nvim.funcs.MoltenAvailableKernels()
                ), "Kernel is not discoverable"
                nvim.exec_lua("""
                    vim.g.notebook_live_ready = false
                    vim.api.nvim_create_autocmd("User", {
                        pattern = "MoltenKernelReady",
                        once = true,
                        callback = function() vim.g.notebook_live_ready = true end,
                    })
                """)
                nvim.api.cmd({"cmd": "MoltenInit", "args": [args.kernel]}, {})
                wait("vim.g.notebook_live_ready", "kernel readiness")
                nvim.current.window.cursor = (
                    list(nvim.current.buffer[:]).index("6 * 9") + 1,
                    0,
                )
                nvim.command("normal! zz")
                callback("ml")
                nvim.funcs.setreg('"', "")
                deadline = time.monotonic() + 30
                while time.monotonic() < deadline:
                    nvim.exec_lua("vim.wait(100, function() return false end, 20)")
                    nvim.command("MoltenYankOutput")
                    if nvim.funcs.getreg('"').strip() == "54":
                        break
                else:
                    raise AssertionError("Timed out: live result 54")
                check(notebook, expected)
                passed(
                    "explicit kernel evaluation returns 54; no export replaces stale disk output 42"
                )
                nvim.command("normal! zz")
                nvim.command("doautocmd CursorMoved")
                nvim.command("redraw")
                source = nvim.current.window.handle
                callback("mo")
                assert (
                    nvim.current.window.handle == source and len(output_windows()) == 1
                )
                output = output_windows()[0]
                callback("mq")
                assert (
                    nvim.current.window.handle == source
                    and not nvim.api.win_is_valid(output)
                )
                passed("actual source mq closes completed output and returns to source")
                for key in ("q", "<Esc>"):
                    callback("mo")
                    assert (
                        nvim.current.window.handle == source
                        and len(output_windows()) == 1
                    )
                    callback("mo")
                    output = nvim.current.window.handle
                    assert (
                        output != source
                        and nvim.current.buffer.options["filetype"] == "molten_output"
                    )
                    assert any("54" in line for line in nvim.current.buffer[:])
                    missing = []
                    for close_key in ("q", "<Esc>"):
                        # Lua callbacks do not survive maparg's RPC serialization.
                        mapped = nvim.exec_lua(
                            'local m = vim.fn.maparg(..., "n", false, true); '
                            'return m.buffer == 1 and type(m.callback) == "function"',
                            close_key,
                        )
                        if not mapped:
                            missing.append(close_key)
                    assert not missing, "Missing output mappings: " + ", ".join(missing)
                    nvim.input("\x1b" if key == "<Esc>" else key)
                    wait(
                        "vim.api.nvim_get_current_win() == " + str(source),
                        key + " output dismissal",
                    )
                    assert not nvim.api.win_is_valid(output)
                    passed(
                        "mo reopens/enters output; actual "
                        + key
                        + " closes it and returns to source"
                    )
                check(notebook, expected)
            else:
                print(
                    "SKIP: live evaluation and output mappings (supply --kernel NAME)",
                    flush=True,
                )
        except Exception:
            if nvim is not None:
                print(
                    "Neovim messages:\n" + nvim.command_output("messages"), flush=True
                )
            raise
        finally:
            if nvim is not None:
                try:
                    if (
                        args.kernel
                        and nvim.current.buffer.options["filetype"] == "molten_output"
                    ):
                        nvim.command("MoltenHideOutput")
                    if args.kernel and nvim.funcs.MoltenRunningKernels(True):
                        nvim.command("MoltenDeinit")
                finally:
                    try:
                        nvim.command("qa!")
                    except EOFError:
                        pass
                    finally:
                        nvim.close()
            assert fixture.read_bytes() == original_bytes, "Original fixture changed"
    passed("original fixture unchanged; disposable copies cleaned up")


if __name__ == "__main__":
    main()
