#!/usr/bin/env python3
"""Lists the RUSTSEC advisories of a repository as a markdown table.

    rustsec.py --repo <owner/repo> [--root <dir>]

It runs `cargo audit` on every Cargo.lock that git tracks below the root, and
reads the open GitHub issues with RUSTSEC in the title. It prints one row per
advisory and crate version.

The Class column is `todo` if a lockfile still holds the version. It is
`solved` if only an issue names it.

If `cargo-audit` is not on PATH, it runs it through `nix shell`.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys

ADVISORY = re.compile(r"RUSTSEC-\d{4}-\d{4}")
TABLE_ROW = re.compile(r"^\|\s*(Package|Version)\s*\|\s*`([^`]+)`")
HEADER = ("Advisory", "Kind", "Crate", "Version", "Patched", "Workspaces", "Issues", "Class")


class Row:
    """One advisory for one crate version."""

    def __init__(self, advisory, crate, version):
        self.advisory = advisory
        self.crate = crate
        self.version = version
        self.kind = ""
        self.title = ""
        self.patched = []
        self.workspaces = []
        self.issues = []

    def cells(self):
        issues = ", ".join(f"#{n}" for n in sorted(self.issues)) or "-"
        if not self.workspaces:
            return (self.advisory, "-", self.crate, self.version, "-", "-", issues, "solved")

        patched = "; ".join(self.patched) or "none"
        workspaces = ", ".join(self.workspaces)
        return (self.advisory, self.kind, self.crate, self.version, patched, workspaces, issues, "todo")


def audit_command():
    """Returns the command that runs cargo-audit."""
    if shutil.which("cargo-audit"):
        return ["cargo-audit"]
    if shutil.which("nix"):
        return ["nix", "shell", "nixpkgs#cargo-audit", "-c", "cargo-audit"]
    sys.exit("cargo-audit is not on PATH, and nix is not there to fetch it")


def lockfiles(root):
    """Returns the folders of the Cargo.lock files that git tracks."""
    out = subprocess.run(["git", "ls-files", "--", "*Cargo.lock"], cwd=root, capture_output=True, text=True, check=True)
    return sorted(os.path.dirname(path) or "." for path in out.stdout.split())


def audit(root, workspaces):
    """Runs cargo audit in each workspace and returns its findings and errors.

    It runs in the workspace folder, so cargo audit reads the
    `.cargo/audit.toml` of that workspace.
    """
    command = audit_command()
    findings = []
    errors = []
    database = None
    for workspace in workspaces:
        # Fetch the advisory database only once.
        extra = ["--no-fetch"] if database else []
        result = subprocess.run(
            [*command, "audit", "--json", *extra, "-f", "Cargo.lock"],
            cwd=os.path.join(root, workspace),
            capture_output=True,
            text=True,
        )
        try:
            report = json.loads(result.stdout)
        except json.JSONDecodeError:
            lines = result.stderr.strip().splitlines() or ["no output"]
            errors.append(f"{workspace}: {lines[-1]}")
            continue

        # A run with --no-fetch reports no database.
        database = database or report.get("database")
        for entry in report["vulnerabilities"]["list"]:
            findings.append((workspace, "vulnerability", entry))
        for kind, entries in report.get("warnings", {}).items():
            for entry in entries:
                # A yanked crate has no advisory.
                if entry.get("advisory"):
                    findings.append((workspace, kind, entry))

    return findings, errors, database or {}


def issues(repo):
    """Returns the open issues with RUSTSEC in the title."""
    out = subprocess.run(
        ["gh", "issue", "list", "--repo", repo, "--state", "open", "--search", "RUSTSEC in:title",
         "--limit", "1000", "--json", "number,title,body"],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(out.stdout)


def build_rows(findings, open_issues):
    """Merges the audit findings and the issues into rows."""
    rows = {}

    def row(advisory, crate, version):
        key = (advisory, crate, version)
        if key not in rows:
            rows[key] = Row(advisory, crate, version)
        return rows[key]

    # The findings of cargo audit.
    for workspace, kind, entry in findings:
        advisory = entry["advisory"]
        package = entry["package"]
        current = row(advisory["id"], package["name"], package["version"])
        current.kind = kind
        current.title = advisory["title"]
        current.patched = entry["versions"]["patched"]
        if workspace not in current.workspaces:
            current.workspaces.append(workspace)

    # The issues. An issue body holds the crate and the version in a table.
    for issue in open_issues:
        match = ADVISORY.search(issue["title"])
        if not match:
            continue
        fields = dict(m.groups() for line in issue["body"].splitlines() if (m := TABLE_ROW.match(line)))
        current = row(match.group(0), fields.get("Package", "?"), fields.get("Version", "?"))
        current.issues.append(issue["number"])
        if not current.title:
            current.title = issue["title"].split(": ", 1)[-1]

    return sorted(rows.values(), key=lambda r: (r.workspaces == [], r.advisory, r.crate, r.version))


def table(rows):
    """Renders the rows as a markdown table with aligned columns."""
    lines = [HEADER] + [r.cells() for r in rows]
    widths = [max(len(line[i]) for line in lines) for i in range(len(HEADER))]

    def render(cells):
        return "| " + " | ".join(c.ljust(w) for c, w in zip(cells, widths)) + " |"

    out = [render(HEADER), "| " + " | ".join("-" * w for w in widths) + " |"]
    out += [render(cells) for cells in lines[1:]]
    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--repo", required=True, help="owner/repo that holds the RUSTSEC issues")
    parser.add_argument("--root", help="repository root (default: the git top level)")
    args = parser.parse_args()

    root = args.root or subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True
    ).stdout.strip()
    workspaces = lockfiles(root)
    findings, errors, database = audit(root, workspaces)
    open_issues = issues(args.repo)
    rows = build_rows(findings, open_issues)

    # The header of the document.
    head = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=root, capture_output=True, text=True).stdout.strip()
    print("# RUSTSEC advisories\n")
    print(f"Repository: {args.repo}, base commit {head}.\n")
    print(f"Advisory database: {database.get('last-updated', '?')}.\n")
    print("Workspaces: " + ", ".join(f"`{w}`" for w in workspaces) + ".\n")
    if errors:
        print("Audit errors:\n")
        print("\n".join(f"- {e}" for e in errors) + "\n")

    # The table and the titles, which are too long for the table.
    print("## Advisories\n")
    print(table(rows) + "\n")
    print("## Titles\n")
    for advisory, title in sorted({(r.advisory, r.title) for r in rows}):
        print(f"- {advisory}: {title}")


if __name__ == "__main__":
    main()
