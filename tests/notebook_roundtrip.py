#!/usr/bin/env python3
"""Check Jupytext's update and paired sync paths using disposable copies only.

Run with the provider Python and pass its jupytext executable as the argument.
No imports outside the standard library, kernels, or dependency installation.
"""

import argparse
import copy
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("jupytext", help="Path to the provider's jupytext CLI")
    args = parser.parse_args()
    executable = shutil.which(args.jupytext)
    if executable is None:
        parser.error(
            "jupytext is missing; install it in the provider environment first"
        )

    fixture = Path(__file__).with_suffix(".ipynb")
    original = json.loads(fixture.read_text())

    def run(*arguments):
        subprocess.run([executable, *map(str, arguments)], check=True)

    def check(notebook, expected):
        actual = json.loads(notebook.read_text())
        for key, value in expected["metadata"].items():
            if key != "jupytext":
                assert actual["metadata"][key] == value, ("notebook metadata", key)
        assert len(actual["cells"]) == len(expected["cells"]), "cell count"
        for index, (got, want) in enumerate(zip(actual["cells"], expected["cells"])):
            assert got["cell_type"] == want["cell_type"], ("cell order/type", index)
            assert "".join(got["source"]) == "".join(want["source"]), (
                "source/order",
                index,
            )
            assert got["metadata"] == want["metadata"], ("cell metadata", index)
            if want["cell_type"] == "code":
                assert got["execution_count"] == want["execution_count"], (
                    "execution count",
                    index,
                )
                assert got["outputs"] == want["outputs"], ("outputs", index)

    with tempfile.TemporaryDirectory(prefix="notebook-roundtrip-") as directory:
        notebook = Path(directory) / "notebook.ipynb"
        script = notebook.with_suffix(".py")
        shutil.copyfile(fixture, notebook)
        run("--from", "ipynb", "--to", "py:percent", "--output", script, notebook)
        run("--to", "ipynb", "--update", "--output", notebook, script)
        check(notebook, original)

        expected = copy.deepcopy(original)
        expected["cells"][0]["source"][1] = "Edited markdown; keep cell order intact."
        script.write_text(
            script.read_text().replace(
                "Keep cell order intact.", "Edited markdown; keep cell order intact."
            )
        )
        run("--to", "ipynb", "--update", "--output", notebook, script)
        check(notebook, expected)

        run("--set-formats", "ipynb,py:percent", notebook)
        run("--sync", notebook)
        check(notebook, expected)
        assert (
            json.loads(notebook.read_text())["metadata"]["jupytext"]["formats"]
            == "ipynb,py:percent"
        )

        # Change the paired text, not code: existing execution results stay valid.
        time.sleep(1.1)  # Make the script newer even on coarse timestamp filesystems.
        script.write_text(
            script.read_text().replace("Edited markdown;", "Paired markdown;")
        )
        expected["cells"][0]["source"][1] = "Paired markdown; keep cell order intact."
        run("--sync", script)
        check(notebook, expected)
        assert (
            json.loads(notebook.read_text())["metadata"]["jupytext"]["formats"]
            == "ipynb,py:percent"
        )

    print(
        "PASS: notebook outputs, execution counts, metadata, cell order, and pairing preserved"
    )


if __name__ == "__main__":
    main()
