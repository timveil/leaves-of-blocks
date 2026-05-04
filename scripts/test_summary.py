#!/usr/bin/env python3
"""
Generate a GitHub-flavored markdown summary from an .xcresult bundle.

Usage:
    scripts/test_summary.py                       # auto-finds latest bundle
    scripts/test_summary.py PATH/TO/BUNDLE.xcresult

Designed to be used in two ways:
1. CI: piped into $GITHUB_STEP_SUMMARY to render on the Actions run page.
2. Local: piped to less / glow / grip to scan after a `./scripts/build.sh test*` run.

Reads the bundle via `xcrun xcresulttool` and `xcrun xccov`. No third-party
dependencies — Python 3 stdlib only.
"""

import glob
import json
import os
import subprocess
import sys
from typing import Any


def xcrun_json(*args: str) -> Any:
    """Invoke xcrun and parse JSON output. Raises on non-zero exit."""
    return json.loads(subprocess.check_output(["xcrun", *args]))


def find_latest_bundle() -> str:
    bundles = sorted(
        glob.glob("build/results/*.xcresult"),
        key=os.path.getmtime,
        reverse=True,
    )
    if not bundles:
        sys.exit("Error: no .xcresult bundle found in build/results/")
    return bundles[0]


def collect_failed_tests(node: dict) -> list[tuple[str, str]]:
    """Walk the testNodes tree and return [(test path, failure message)]."""
    failures = []

    def walk(n: dict, path: list[str]) -> None:
        name = n.get("name", "?")
        node_type = n.get("nodeType", "")
        new_path = path + [name] if node_type in ("Test Suite", "Test Case") else path

        if n.get("result") == "Failed" and node_type == "Test Case":
            messages = []
            for child in n.get("children", []):
                if child.get("nodeType") in ("Failure Message", "Issue"):
                    msg = child.get("name", "").strip()
                    if msg:
                        messages.append(msg)
            failures.append((" / ".join(new_path), " · ".join(messages) or "(no detail)"))

        for child in n.get("children", []):
            walk(child, new_path)

    for top in node.get("testNodes", []):
        walk(top, [])
    return failures


def coverage_table(bundle: str) -> str:
    """Per-target line coverage as a markdown table."""
    try:
        out = subprocess.check_output(
            ["xcrun", "xccov", "view", "--report", "--only-targets", bundle],
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except subprocess.CalledProcessError:
        return ""

    rows = []
    for line in out.splitlines():
        # Format: "ID Name  # Source Files  Coverage" then data rows.
        parts = line.split()
        if len(parts) < 4 or not parts[0].isdigit():
            continue
        # Coverage is "XX.XX% (covered/total)" — last 2 tokens.
        target = " ".join(parts[1:-3])
        files = parts[-3]
        pct = parts[-2]
        ratio = parts[-1]
        rows.append((target, files, pct, ratio))

    if not rows:
        return ""

    md = ["### Coverage", "", "| Target | Files | Line Coverage |", "|---|---:|---|"]
    for target, files, pct, ratio in rows:
        md.append(f"| `{target}` | {files} | **{pct}** {ratio} |")
    return "\n".join(md)


def main() -> int:
    bundle = sys.argv[1] if len(sys.argv) > 1 else find_latest_bundle()
    if not os.path.isdir(bundle):
        sys.exit(f"Error: bundle not found or not a directory: {bundle}")

    summary = xcrun_json("xcresulttool", "get", "test-results", "summary", "--path", bundle)
    tests = xcrun_json("xcresulttool", "get", "test-results", "tests", "--path", bundle)

    passed = summary.get("passedTests", 0)
    failed = summary.get("failedTests", 0)
    skipped = summary.get("skippedTests", 0)
    total = summary.get("totalTestCount", passed + failed + skipped)
    result = summary.get("result", "Unknown")
    duration = summary.get("finishTime", 0) - summary.get("startTime", 0)
    title = summary.get("title", "Tests")

    icon = "✅" if result == "Passed" else "❌"
    out: list[str] = []
    out.append(f"## {icon} {title}")
    out.append("")
    out.append(f"**{passed} passed**, {failed} failed, {skipped} skipped — {total} total in {duration:.1f}s")
    out.append("")

    failures = collect_failed_tests(tests)
    if failures:
        out.append("### Failed Tests")
        out.append("")
        for name, msg in failures:
            # Trim long failure messages so the summary stays readable.
            short = msg if len(msg) <= 400 else msg[:400] + "…"
            out.append(f"- **{name}**")
            out.append(f"  ```")
            out.append(f"  {short}")
            out.append(f"  ```")
        out.append("")

    cov = coverage_table(bundle)
    if cov:
        out.append(cov)
        out.append("")

    out.append(f"_Bundle: `{os.path.relpath(bundle)}`_")

    print("\n".join(out))
    return 0 if result == "Passed" else 1


if __name__ == "__main__":
    sys.exit(main())
