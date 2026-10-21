# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

"""Measure every owned Lua function without executing inspected source.

Lizard owns cyclomatic counts. The repository's lua-cognitive-v1 convention
counts structured decisions with nesting, else/elseif without a nesting bonus,
boolean operator sequences, jumps, and direct recursion. Nested functions start
an independent scope. This is a documented Lua metric, not a SonarQube score.
"""

import argparse
import hashlib
import importlib.metadata
import json
import re

# Process calls below use reviewed literal argv and never a shell.
import subprocess  # nosec B404
from collections.abc import Iterator
from pathlib import Path
from types import SimpleNamespace
from typing import Any

import lizard
from luaparser import ast
from luaparser import astnodes as nodes

FunctionNode = (
    nodes.Function | nodes.LocalFunction | nodes.Method | nodes.AnonymousFunction
)

FUNCTIONS = (nodes.Function, nodes.LocalFunction, nodes.Method, nodes.AnonymousFunction)
LOOPS = (nodes.While, nodes.Repeat, nodes.Fornum, nodes.Forin)
BOOLEAN = (nodes.AndLoOp, nodes.OrLoOp)


def children(node: nodes.Node) -> Iterator[nodes.Node]:
    """Visit semantic fields once, omitting tokens, comments and metadata."""
    for key, value in vars(node).items():
        if key.startswith("_") or key == "comments":
            continue
        if isinstance(value, nodes.Node):
            yield value
        elif isinstance(value, list):
            yield from (item for item in value if isinstance(item, nodes.Node))


def logical_sequence(node: nodes.Node) -> list[str]:
    """Flatten one boolean expression while preserving operator changes."""
    if not isinstance(node, BOOLEAN):
        return []
    return [
        *logical_sequence(node.left),
        type(node).__name__,
        *logical_sequence(node.right),
    ]


def cognitive(node: nodes.Node, depth: int = 0, boolean_parent: bool = False) -> int:
    """Count one function's flow; nested declarations belong to their own row."""
    if isinstance(node, FUNCTIONS):
        return 0
    if isinstance(node, nodes.If):
        alternate = node.orelse
        score = 1 + depth + cognitive(node.test) + cognitive(node.body, depth + 1)
        if isinstance(alternate, nodes.ElseIf):
            score += cognitive(alternate, depth)
        elif isinstance(alternate, nodes.Block):
            score += 1 + cognitive(alternate, depth + 1)
        return score
    if isinstance(node, nodes.ElseIf):
        alternate = node.orelse
        score = 1 + cognitive(node.test) + cognitive(node.body, depth + 1)
        if isinstance(alternate, nodes.ElseIf):
            score += cognitive(alternate, depth)
        elif isinstance(alternate, nodes.Block):
            score += 1 + cognitive(alternate, depth + 1)
        return score
    if isinstance(node, LOOPS):
        return (
            1
            + depth
            + sum(
                cognitive(child, depth + 1 if child is node.body else depth)
                for child in children(node)
            )
        )
    if isinstance(node, (nodes.Goto, nodes.Break)):
        return 1
    logical = isinstance(node, BOOLEAN)
    operators = logical_sequence(node) if logical and not boolean_parent else []
    score = sum(
        index == 0 or operator != operators[index - 1]
        for index, operator in enumerate(operators)
    )
    return score + sum(cognitive(child, depth, logical) for child in children(node))


def function_nodes(tree: nodes.Node) -> Iterator[FunctionNode]:
    """Include factories, methods, callbacks, fixtures and nested helpers."""
    if isinstance(tree, FUNCTIONS):
        yield tree
    for child in children(tree):
        yield from function_nodes(child)


def directly_recursive(body: nodes.Node, name: str) -> bool:
    """Recognize lexical self-calls; do not guess dynamic table dispatch cycles."""
    if isinstance(body, FUNCTIONS):
        return False
    if (
        isinstance(body, nodes.Call)
        and isinstance(body.func, nodes.Name)
        and body.func.id == name
    ):
        return True
    return any(directly_recursive(child, name) for child in children(body))


def direct_nodes(node: nodes.Node) -> Iterator[nodes.Node]:
    """Visit a lexical body without traversing nested function scopes."""
    yield node
    if not isinstance(node, FUNCTIONS):
        for child in children(node):
            yield from direct_nodes(child)


def cyclomatic(function: FunctionNode, source: str) -> int:
    """Measure an AST-isolated body using the pinned Lizard decision counter.

    Lizard's Lua scanner can lose enclosing scopes around nested methods and
    embedded language strings. The parser establishes those boundaries first;
    replacing nested declarations and string contents preserves this function's
    decisions while avoiding counts from another function or embedded language.
    """
    body = function.body
    start, stop = body.start_char, body.stop_char
    if start is None or stop is None:
        return 1
    text = source[start : stop + 1]
    edits = []
    for node in direct_nodes(body):
        if isinstance(node, (*FUNCTIONS, nodes.String)):
            replacement = "nil" if isinstance(node, nodes.AnonymousFunction) else ""
            if isinstance(node, nodes.String):
                replacement = '"literal"'
            begin, end = node.start_char, node.stop_char
            if begin is None or end is None:
                raise ValueError("Parser omitted lexical source boundaries")
            edits.append((begin - start, end + 1 - start, replacement))
    for begin, end, replacement in sorted(edits, reverse=True):
        text = text[:begin] + replacement + text[end:]
    stream = ast.get_token_stream(text)
    stream.fill()
    tokens = (token.text for token in stream.tokens if token.channel == 0)
    context = lizard.FileInfoBuilder("measured.lua")
    reader = SimpleNamespace(
        context=context,
        conditions={"if", "elseif", "for", "while", "until", "and", "or"},
    )
    for _ in lizard.condition_counter(tokens, reader):
        pass
    return context.current_function.cyclomatic_complexity


def function_contract(function: FunctionNode, lines: list[str]) -> dict[str, Any]:
    """Check adjacent LDoc tags without executing code or reading string contents."""
    first = function.first_token
    if first is None:
        raise ValueError("Parser omitted function source boundaries")
    prefix = lines[first.line - 1][: first.column]
    index = first.line - 2
    if re.search(r"\bfunction\b", prefix):
        index = -1
    comments: list[str] = []
    while index >= 0 and lines[index].lstrip().startswith("--"):
        comments.insert(0, lines[index].strip())
        index -= 1
    documentation = "\n".join(comments)
    parameters = [getattr(argument, "id", "...") for argument in function.args]
    missing = [
        name
        for name in parameters
        if not re.search(r"@param\s+" + re.escape(name) + r"(?:\s|$)", documentation)
    ]
    return {
        "missing_parameters": missing,
        "documented_return": bool(re.search(r"@return\s+\S", documentation)),
        "documented_purpose": any(
            re.match(r"---\s+[^@\s]", comment) for comment in comments
        ),
    }


def measure_source(path: str, source: str) -> list[dict[str, Any]]:
    """Measure every AST function; parser failures never become absent rows."""
    rows = []
    lines = source.splitlines()
    for function in function_nodes(ast.parse(source)):
        name = getattr(getattr(function, "name", None), "id", "anonymous")
        first, last = function.first_token, function.last_token
        if first is None or last is None:
            raise ValueError("Parser omitted function source boundaries")
        rows.append(
            {
                "file": path,
                "name": name,
                "line": first.line,
                "end_line": last.line,
                "cyclomatic": cyclomatic(function, source),
                "cognitive": cognitive(function.body)
                + int(directly_recursive(function.body, name)),
                "parameters": len(function.args),
                "contract": function_contract(function, lines),
            }
        )
    return rows


def sources() -> list[str]:
    """Use Git's NUL-delimited working inventory, including extensionless hooks."""
    command = ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"]
    # Fixed Git inventory arguments; no source content becomes command text.
    names = subprocess.check_output(command).decode().split("\0")  # nosec B603
    result = []
    for name in sorted(set(names) - {""}):
        path = Path(name)
        if not path.is_file():
            continue
        with path.open("rb") as handle:
            header = handle.readline()
        if path.suffix == ".lua" or re.fullmatch(rb"#!.*[/\s]lua\s*", header):
            result.append(name)
    return result


def main() -> None:
    """Retain complete measurements and parser errors before failing the gate."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", default=".cache/ci/lua-quality/report.json")
    parser.add_argument("--report-only", action="store_true")
    args = parser.parse_args()
    manifest = Path("tools/analysis/c/gates.json").read_bytes()
    limits = json.loads(manifest)["limits"]
    functions, errors, inputs = [], [], {}
    for path in sources():
        content = Path(path).read_bytes()
        inputs[path] = hashlib.sha256(content).hexdigest()
        try:
            functions.extend(measure_source(path, content.decode()))
        except (ValueError, ast.SyntaxException) as error:
            errors.append(f"{path}: {error}")
    if not inputs:
        errors.append("Git inventory contains no Lua source")
    violations = [
        row
        for row in functions
        if row["cyclomatic"] > limits["cyclomatic"]
        or row["cognitive"] > limits["cognitive"]
    ]
    contract_violations = [
        row
        for row in functions
        if row["contract"]["missing_parameters"]
        or not row["contract"]["documented_return"]
        or not row["contract"]["documented_purpose"]
    ]
    failed = bool(violations or contract_violations or errors)
    result = {
        "schema": 1,
        "state": "FAIL" if failed else "PASS",
        "engines": {
            "lizard": importlib.metadata.version("lizard"),
            "luaparser": importlib.metadata.version("luaparser"),
            "cyclomatic": "lua-ast-lizard-v1",
            "cognitive": "lua-cognitive-v1",
        },
        "limits": {key: limits[key] for key in ("cyclomatic", "cognitive")},
        "manifest_sha256": hashlib.sha256(manifest).hexdigest(),
        "sources": inputs,
        "functions": functions,
        "violations": violations,
        "contract_violations": contract_violations,
        "errors": errors,
    }
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + "\n")
    print(
        f"Lua complexity: {result['state']}; {len(inputs)} files; "
        f"{len(functions)} functions; {len(violations)} violations; "
        f"{len(contract_violations)} contract violations; "
        f"{len(errors)} analyzer errors"
    )
    raise SystemExit(bool(errors or (failed and not args.report_only)))


if __name__ == "__main__":
    main()

# EOF

