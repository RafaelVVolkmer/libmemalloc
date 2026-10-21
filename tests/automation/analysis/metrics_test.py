# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

"""Challenge real quality engines with excessive complexity and renamed clones."""

import importlib.util
import json
import tempfile
from pathlib import Path


def main() -> None:
    """Reject semantic fixtures and require the cognitive checker to execute."""
    specification = importlib.util.spec_from_file_location(
        "metrics", "tools/analysis/c/metrics.py"
    )
    if specification is None or specification.loader is None:
        raise RuntimeError("Metrics adapter cannot be loaded")
    metrics = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(metrics)
    limits = json.loads(Path("tools/analysis/c/gates.json").read_text())["limits"]
    with tempfile.TemporaryDirectory(
        prefix="quality-", dir=".cache/tests"
    ) as directory:
        first = Path(directory) / "first.c"
        second = Path(directory) / "second.c"
        statements = "\n".join(f"if (x == {i}) x += {i + 1};" for i in range(20))
        first.write_text(f"int first(int x) {{ {statements} return x; }}\n")
        second.write_text(
            first.read_text().replace("first", "second").replace("x", "y")
        )
        result = metrics.measure([str(first), str(second)], limits)
        if not result["violations"]:
            raise RuntimeError("Cyclomatic overflow was accepted")
        if not result["duplicate_groups"]:
            raise RuntimeError("Renamed code clone was accepted")
    print("Quality engines: complexity and renamed-clone rejection passed")


if __name__ == "__main__":
    main()

# EOF

