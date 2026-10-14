# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

"""Challenge Lua metrics with lexical traps, nested scopes and failing gates."""

import importlib.util
import json

# Process calls below use reviewed literal argv and never a shell.
import subprocess  # nosec B404
import sys
import tempfile
import unittest
from pathlib import Path


def load_metrics():
    """Load the production adapter without running its command entry point."""
    specification = importlib.util.spec_from_file_location(
        "lua_metrics", "tools/analysis/lua/metrics.py"
    )
    if specification is None or specification.loader is None:
        raise RuntimeError("Lua metrics adapter cannot be loaded")
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


class LuaMetricsTests(unittest.TestCase):
    """Assert metric values independently of repository source complexity."""

    def setUp(self) -> None:
        self.metrics = load_metrics()

    def scores(self, source: str) -> list[tuple[int, int]]:
        """Measure fixture text; no Lua statements are executed."""
        return [
            (row["cyclomatic"], row["cognitive"])
            for row in self.metrics.measure_source("fixture.lua", source)
        ]

    def test_straight_line_and_empty_functions(self) -> None:
        self.assertEqual(self.scores("local function f() end"), [(1, 0)])
        self.assertEqual(self.scores("local function f() return 42 end"), [(1, 0)])

    def test_decisions_and_nesting(self) -> None:
        self.assertEqual(
            self.scores(
                "local function f(x) if x then while x do x=x-1 end "
                "elseif x == nil then return 0 else return 1 end end"
            ),
            [(4, 5)],
        )

    def test_boolean_sequences(self) -> None:
        self.assertEqual(
            self.scores("local function f(a,b,c,d) return a and b and c or d end"),
            [(4, 2)],
        )

    def test_nested_boolean_sequences(self) -> None:
        self.assertEqual(
            self.scores("local function f(a,b,c,d) return a and (b or c) and d end"),
            [(4, 3)],
        )

    def test_nested_scopes_are_independent(self) -> None:
        self.assertEqual(
            self.scores(
                "local function outer(x) local function inner(y) "
                "if y then return y end end if x then return inner(x) end end"
            ),
            [(2, 1), (2, 1)],
        )

    def test_methods_and_callbacks(self) -> None:
        self.assertEqual(
            self.scores(
                "function t:method(x) local cb = function(y) "
                "return y and 1 or 0 end return cb(x) end"
            ),
            [(1, 0), (3, 2)],
        )

    def test_literals_comments_unicode_and_ruby_words(self) -> None:
        self.assertEqual(
            self.scores(
                "local function f() local module, class = 'ação', [==["
                "if for while and or function end]==] "
                "--[=[ if if end ]=]\nreturn module .. class end"
            ),
            [(1, 0)],
        )

    def test_all_loop_forms_and_jumps(self) -> None:
        self.assertEqual(
            self.scores(
                "local function f(t) for i=1,2 do end for k in pairs(t) do end "
                "while true do break end repeat goto finish until true "
                "::finish:: end"
            ),
            [(5, 6)],
        )

    def test_direct_recursion(self) -> None:
        self.assertEqual(
            self.scores(
                "local function f(n) if n>0 then return f(n-1) end return 0 end"
            ),
            [(2, 2)],
        )

    def test_invalid_syntax_is_an_error(self) -> None:
        with self.assertRaises(self.metrics.ast.SyntaxException):
            self.scores("local function broken(")

    def run_gate(self, source: str, report_only: bool = False):
        """Run the real CLI against a Git inventory and the production limits."""
        adapter = Path("tools/analysis/lua/metrics.py").resolve()
        manifest = Path("tools/analysis/c/gates.json").read_bytes()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            # Fixed Git command and a generated temporary directory.
            subprocess.run(  # nosec B603, B607
                ["git", "init", "--quiet", directory], check=True
            )
            gate = root / "tools/analysis/c/gates.json"
            gate.parent.mkdir(parents=True)
            gate.write_bytes(manifest)
            (root / "fixture.lua").write_text(source)
            (root / ".gitignore").write_text(".cache/\n")
            cache = root / ".cache/dependency.lua"
            cache.parent.mkdir()
            cache.write_text("this must not be parsed")
            hook = root / "hook"
            hook.write_text(
                "#!/usr/bin/env lua\n--- Run hook.\n-- @return nil: no values.\n"
                "local function h() end return h()"
            )
            (root / "direct-hook").write_text(
                "#!/usr/bin/lua\n--- Run hook.\n-- @return nil: no values.\n"
                "local function h() end return h()"
            )
            command = [sys.executable, str(adapter)]
            if report_only:
                command.append("--report-only")
            # Absolute interpreter and reviewed adapter, with fixed flags.
            result = subprocess.run(  # nosec B603
                command, cwd=root, capture_output=True, check=False
            )
            report = json.loads(
                (root / ".cache/ci/lua-quality/report.json").read_text()
            )
            return result.returncode, report

    def test_cli_inventory_and_fail_closed_thresholds(self) -> None:
        decisions = " ".join(f"if x=={value} then x=x+1 end" for value in range(16))
        status, report = self.run_gate(f"local function f(x) {decisions} end")
        self.assertNotEqual(status, 0)
        self.assertEqual(set(report["sources"]), {"fixture.lua", "hook", "direct-hook"})
        self.assertEqual(len(report["violations"]), 1)
        self.assertEqual(report["violations"][0]["cyclomatic"], 17)
        self.assertEqual(report["violations"][0]["cognitive"], 16)
        self.assertEqual(report["limits"], {"cyclomatic": 10, "cognitive": 15})
        self.assertEqual(report["errors"], [])

    def test_report_only_never_hides_parser_failure(self) -> None:
        status, report = self.run_gate("local function broken(", report_only=True)
        self.assertNotEqual(status, 0)
        self.assertTrue(report["errors"])
        self.assertEqual(report["state"], "FAIL")

    def test_contracts_require_each_parameter_and_return(self) -> None:
        source = (
            "--- Inspect input.\n-- @param data string: input.\n"
            "local function f(a, data) return a end"
        )
        row = self.metrics.measure_source("fixture.lua", source)[0]
        self.assertEqual(row["contract"]["missing_parameters"], ["a"])
        self.assertFalse(row["contract"]["documented_return"])
        status, report = self.run_gate(source)
        self.assertNotEqual(status, 0)
        self.assertEqual(len(report["contract_violations"]), 1)

    def test_contracts_do_not_leak_to_nested_callbacks(self) -> None:
        source = (
            "--- Construct a callback.\n-- @return function: callback.\n"
            "local function f() return function(value) return value end end"
        )
        rows = self.metrics.measure_source("fixture.lua", source)
        self.assertTrue(rows[0]["contract"]["documented_purpose"])
        self.assertFalse(rows[1]["contract"]["documented_purpose"])
        self.assertEqual(rows[1]["contract"]["missing_parameters"], ["value"])

    def test_cli_accepts_valid_source(self) -> None:
        status, report = self.run_gate(
            "--- Return the fixture value.\n-- @return number: fixture value.\n"
            "local function f() return 42 end return f()"
        )
        self.assertEqual(status, 0)
        self.assertEqual(report["state"], "PASS")


if __name__ == "__main__":
    unittest.main()

# EOF

