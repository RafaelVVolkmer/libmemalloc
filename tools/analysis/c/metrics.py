# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

"""Measure owned C/C++ sources with Lizard and emit machine-readable gate evidence.

The Lua quality controller owns execution. This adapter uses Lizard's Python API
so clone groups and per-function counts do not depend on parsing console tables.
"""

import argparse
import hashlib
import importlib.metadata
import json
from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import Any

import lizard
from lizard_ext.lizardduplicate import LizardExtension


def measure(paths: Sequence[str], limits: Mapping[str, int]) -> dict[str, Any]:
    """Collect function complexity and token-normalized duplicate groups."""
    duplicate = LizardExtension()
    extensions = [*lizard.get_extensions([]), duplicate]
    files = list(lizard.analyze_files(paths, threads=1, exts=extensions))
    functions = [
        {
            "file": item.filename,
            "name": function.name,
            "line": function.start_line,
            "cyclomatic": function.cyclomatic_complexity,
        }
        for item in files
        for function in item.function_list
    ]
    clones = [
        [
            {
                "file": snippet.file_name,
                "start": snippet.start_line,
                "end": snippet.end_line,
            }
            for snippet in group
        ]
        for group in duplicate.get_duplicates(limits["duplicate_min_tokens"])
    ]
    violations = [f for f in functions if f["cyclomatic"] > limits["cyclomatic"]]
    return {
        "engine": f"lizard {importlib.metadata.version('lizard')}",
        "functions": functions,
        "duplicate_groups": clones,
        "violations": violations,
        "state": "FAIL"
        if violations or len(clones) > limits["duplicate_blocks"]
        else "PASS",
    }


def main() -> None:
    """Read a reviewed threshold manifest and preserve evidence before failing."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("sources", nargs="+")
    args = parser.parse_args()
    manifest = Path(args.manifest).read_bytes()
    limits = json.loads(manifest)["limits"]
    result = measure(args.sources, limits)
    result["limits"] = limits
    result["manifest_sha256"] = hashlib.sha256(manifest).hexdigest()
    result["sources"] = {
        path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
        for path in args.sources
    }
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + "\n")
    print(
        f"Lizard: {result['state']}; {len(result['functions'])} functions; "
        f"{len(result['duplicate_groups'])} duplicate groups"
    )
    raise SystemExit(result["state"] != "PASS")


if __name__ == "__main__":
    main()

# EOF

