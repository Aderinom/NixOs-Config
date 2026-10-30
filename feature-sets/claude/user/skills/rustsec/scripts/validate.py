#!/usr/bin/env python3
"""Checks advisories against every Cargo.lock, straight from the advisory database.

    validate.py [--root <dir>] [--db <dir>] [--skip <workspace>]... <RUSTSEC-ID>...

For each advisory, it prints the `patched` and `unaffected` ranges, and each
locked version of the crate per lockfile, marked `ok`, `AFFECTED`, or
`IGNORED`. `IGNORED` means that the `.cargo/audit.toml` of the workspace lists
the advisory.

It also flags a withdrawn advisory, and the `arch` and `os` limits of an
advisory. cargo audit reports such an advisory on every platform.

The database defaults to `~/.cargo/advisory-db`, which cargo audit fetches.
"""

import argparse
import glob
import os
import re
import subprocess
import sys
import tomllib

COMPARATOR = re.compile(r"\s*(>=|<=|>|<|=|\^)?\s*(\S+)")


def parse_version(text):
    """Turns a version into a tuple that sorts like semver, without build metadata."""
    core, _, pre = text.split("+", 1)[0].partition("-")
    parts = [int(p) for p in core.split(".")] + [0, 0]
    return (parts[0], parts[1], parts[2], 0 if pre else 1, pre)


def matches(version, requirement):
    """Returns true if the version meets every comparator of the requirement."""
    for comparator in requirement.split(","):
        op, bound = COMPARATOR.match(comparator).groups()
        bound = parse_version(bound)
        if (op or "^") == "^":
            # A caret keeps the left-most non-zero part.
            if bound[0] > 0:
                upper = (bound[0] + 1, 0, 0, 0, "")
            elif bound[1] > 0:
                upper = (0, bound[1] + 1, 0, 0, "")
            else:
                upper = (0, 0, bound[2] + 1, 0, "")
            ok = bound <= version < upper
        else:
            ok = {">=": version >= bound, "<=": version <= bound, ">": version > bound,
                  "<": version < bound, "=": version == bound}[op]
        if not ok:
            return False

    return True


def load_workspaces(root, skip):
    """Returns the locked packages and the ignored advisories of each workspace."""
    out = subprocess.run(["git", "ls-files", "--", "*Cargo.lock"], cwd=root, capture_output=True, text=True, check=True)
    packages = {}
    ignored = {}
    for lock in out.stdout.split():
        workspace = os.path.dirname(lock) or "."
        if workspace in skip:
            continue

        for package in tomllib.load(open(os.path.join(root, lock), "rb")).get("package", []):
            packages.setdefault(package["name"], []).append((workspace, package["version"]))

        # cargo audit reads the audit.toml of the folder it runs in.
        config = os.path.join(root, workspace, ".cargo", "audit.toml")
        if os.path.exists(config):
            ignored[workspace] = set(tomllib.load(open(config, "rb")).get("advisories", {}).get("ignore", []))

    return packages, ignored


def check(advisory_id, db, packages, ignored):
    """Prints one advisory and the state of each locked version of its crate."""
    paths = glob.glob(f"{db}/**/{advisory_id}.md", recursive=True)
    if not paths:
        print(f"{advisory_id}: NOT IN DATABASE")
        return

    # The advisory file starts with a TOML block.
    text = open(paths[0], encoding="utf-8").read()
    meta = tomllib.loads(re.search(r"```toml\n(.*?)```", text, re.S).group(1))
    advisory = meta["advisory"]
    versions = meta.get("versions", {})
    safe_ranges = versions.get("patched", []) + versions.get("unaffected", [])

    flags = []
    if advisory.get("withdrawn"):
        flags.append(f"WITHDRAWN {advisory['withdrawn']}")
    limits = {k: v for k, v in meta.get("affected", {}).items() if k in ("arch", "os")}
    if limits:
        flags.append(f"limits {limits}")
    print(f"{advisory_id} {advisory['package']} patched={versions.get('patched', [])} "
          f"unaffected={versions.get('unaffected', [])} {' '.join(flags)}".rstrip())

    locked = sorted(packages.get(advisory["package"], []))
    if not locked:
        print("    (crate in no lockfile)")
    for workspace, version in locked:
        if any(matches(parse_version(version), r) for r in safe_ranges):
            state = "ok"
        elif advisory_id in ignored.get(workspace, ()):
            state = "IGNORED"
        else:
            state = "AFFECTED"
        print(f"    {state:8} {version:20} {workspace}")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("ids", nargs="+", metavar="RUSTSEC-ID")
    parser.add_argument("--root", help="repository root (default: the git top level)")
    parser.add_argument("--db", default=os.path.expanduser("~/.cargo/advisory-db"), help="advisory database folder")
    parser.add_argument("--skip", action="append", default=[], help="workspace to leave out, for example third_party/x")
    args = parser.parse_args()

    root = args.root or subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True
    ).stdout.strip()
    if not os.path.isdir(args.db):
        sys.exit(f"no advisory database at {args.db}; run cargo audit once to fetch it")

    packages, ignored = load_workspaces(root, set(args.skip))
    for advisory_id in args.ids:
        check(advisory_id, args.db, packages, ignored)


if __name__ == "__main__":
    main()
