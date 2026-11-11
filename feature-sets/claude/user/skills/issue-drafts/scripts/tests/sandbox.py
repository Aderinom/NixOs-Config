#!/usr/bin/env python3
"""Tests issues.py against a sandbox repository and board.

    python3 tests/sandbox.py [--repo Aderinom/issues-sandbox] [--project Aderinom/3]

Each run creates a root issue and works below it, so two runs share no
state. At the end, the run closes every issue that it created.

The board needs the Status options `Todo`, `In Progress`, and `Done`, and a
Priority field with `high` and `low`.

If an auto-add workflow adds issues with the label `area/api`, the run also
takes the path of the board race.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time

SCRIPTS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, SCRIPTS)

import issues  # noqa: E402

SECTIONS = "## Goal\n\nA test issue.\n\n## Scope\n\n- [ ] Nothing.\n\n## Definition of done\n\n- [ ] Nothing.\n"


class Run:
    """The state of one test run: the repository, the board, and the results."""

    def __init__(self, repo, project):
        self.repo = repo
        self.project = project
        self.board = issues.Board.named(project)
        self.failures = []

    def script(self, *args):
        """Runs issues.py and returns the exit code and the output."""
        result = subprocess.run(
            [sys.executable, os.path.join(SCRIPTS, "issues.py"), *args, "--repo", self.repo, "--project", self.project],
            capture_output=True, text=True,
        )
        return result.returncode, result.stdout + result.stderr

    def remote(self, number):
        return issues.Remote.fetch(self.repo, number, self.board)

    def expect(self, name, condition, detail=""):
        print(f"{'PASS' if condition else 'FAIL'}  {name}" + ("" if condition else f"\n      {detail}"))
        if not condition:
            self.failures.append(name)


def write(path, meta, body=SECTIONS):
    """Writes a draft with the front matter `meta`, in the order of the dict."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    lines = ["---"]
    for key, value in meta.items():
        if isinstance(value, list):
            lines.append(f"{key}: [{', '.join(value)}]")
        else:
            lines.append(f"{key}: {value}")
    lines.append("---")
    with open(path, "w", encoding="utf-8") as out:
        out.write("\n".join(lines) + "\n\n" + body)


def edit(path, **changes):
    """Sets front matter keys of a draft."""
    draft = issues.Draft(path, "00", None)
    for key, value in changes.items():
        draft.set_meta(key, value)


def check_rejections(run, work, root, existing):
    """`check` refuses broken drafts, and accepts an existing issue without the sections."""
    folder = os.path.join(work, f"{root}-bad.sub")
    base = {"labels": [], "parent": f'"#{root}"', "status": "Todo", "assignees": [], "issue": ""}
    write(os.path.join(folder, "01-wrong-parent.md"), {**base, "title": '"test: wrong parent"', "parent": '"#999999"'})
    write(os.path.join(folder, "02-unknown-label.md"), {**base, "title": '"test: unknown label"', "labels": ["no/such-label"]})
    write(os.path.join(folder, "03-bad-status.md"), {**base, "title": '"test: bad status"', "status": "Nowhere"})
    write(os.path.join(folder, "04-no-sections.md"), {**base, "title": '"test: no sections"'}, "Only text.\n")
    write(os.path.join(folder, "05-no-status.md"), {**base, "title": '"test: no status"', "status": ""})
    write(os.path.join(folder, "06-old-issue.md"), {
        **base, "title": '"test: old issue"', "issue": f"https://github.com/{run.repo}/issues/{existing}",
    }, "An old issue without the sections.\n")
    code, out = run.script("check", folder)

    run.expect("check fails on broken drafts", code != 0, out)
    run.expect("check refuses a wrong parent", "01-wrong-parent.md: the parent is `#999999`" in out, out)
    run.expect("check refuses an unknown label", "`no/such-label` does not exist" in out, out)
    run.expect("check refuses a status that is not on the board", "the status `Nowhere` is not one of" in out, out)
    run.expect("check needs the sections in a new draft", "04-no-sections.md: no `## Goal` section" in out, out)
    run.expect("check needs a status in a new draft", "05-no-status.md: a new issue needs a status" in out, out)
    run.expect("check accepts an existing issue without the sections", "06-old-issue.md" not in out, out)


def resume(run, work, root):
    """A second `apply` finishes a run that stopped, without duplicates and without a false conflict."""
    folder = os.path.join(work, f"{root}-resume.sub")
    base = {"labels": [], "parent": f'"#{root}"', "status": "Todo", "assignees": [], "issue": ""}
    title = 'test: gamma "quoted": with colon'
    write(os.path.join(folder, "01-gamma.md"), {**base, "title": json.dumps(title)})
    write(os.path.join(folder, "01-gamma.sub", "01-epsilon.md"), {**base, "title": '"test: epsilon"', "parent": '"../01-gamma.md"'})
    delta_file = os.path.join(folder, "02-delta.md")
    write(delta_file, {**base, "title": '"test: delta"', "blocked_by": ['"#999999"']})

    # The blocker #999999 does not exist, so apply stops after it created the issues. Gamma has a draft and a new sub-issue.
    code, out = run.script("apply", folder)
    run.expect("apply stops at a missing blocker", code != 0, out)
    gamma, epsilon, delta = (draft.issue for draft in issues.Tree(folder).walk())
    run.expect("apply wrote the issues of the stopped run", gamma and epsilon and delta, (gamma, epsilon, delta))

    # Fix the blocker, and run apply again.
    edit(delta_file, blocked_by='["01-gamma.md"]')
    code, out = run.script("apply", folder)
    run.expect("apply resumes without a conflict", code == 0 and "conflict" not in out, out)
    run.expect("apply resumes without a second create", "create " not in out, out)
    children = json.loads(issues.gh("api", f"repos/{run.repo}/issues/{root}/sub_issues", "--jq", "[.[].title]"))
    run.expect("the root has gamma and delta once", children.count(title) == 1 and children.count("test: delta") == 1, children)
    grandchildren = json.loads(issues.gh("api", f"repos/{run.repo}/issues/{gamma}/sub_issues", "--jq", "[.[].title]"))
    run.expect("gamma has epsilon once", grandchildren == ["test: epsilon"], grandchildren)
    run.expect("delta is blocked by gamma", run.remote(delta).blocked_by == [f"{run.repo}#{gamma}"], run.remote(delta).blocked_by)

    # The quoted title survives the round trip.
    run.expect("a title with quotes and a colon survives", run.remote(gamma).title == title, run.remote(gamma).title)
    code, out = run.script("plan", folder)
    run.expect("plan after the resume has no changes", code == 0 and "no changes" in out, out)


def drafted_issues(work):
    """The issue numbers in all drafts below `work`."""
    numbers = set()
    for root, _, files in os.walk(work):
        for name in files:
            match = issues.URL.search(issues.Draft(os.path.join(root, name), "00", None).meta.get("issue", ""))
            if match:
                numbers.add(int(match.group("number")))
    return numbers


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--repo", default="Aderinom/issues-sandbox")
    parser.add_argument("--project", default="Aderinom/3")
    args = parser.parse_args()
    run = Run(args.repo, args.project)
    work = tempfile.mkdtemp(prefix="issues-sandbox-")
    created = []

    # Create the root issue of this run.
    url = issues.gh("issue", "create", "--repo", run.repo, "--title", f"test: run {time.strftime('%Y-%m-%d %H:%M:%S')}", "--body", "Root of a sandbox test run.")
    root = int(url.rsplit("/", 1)[-1])
    created.append(root)
    print(f"root #{root}, work folder {work}")

    try:
        # Write a tree with a sub-issue, a blocker, and a reference.
        folder = os.path.join(work, f"{root}-run.sub")
        write(os.path.join(folder, "01-alpha.md"), {
            "title": '"test: alpha"', "labels": ["area/docs"], "parent": f'"#{root}"',
            "status": "Todo", "priority": "high", "assignees": [], "issue": "",
        })
        write(os.path.join(folder, "01-alpha.sub", "01-alpha-child.md"), {
            "title": '"test: alpha child"', "labels": [], "parent": '"../01-alpha.md"',
            "status": "Todo", "assignees": ["@me"], "issue": "",
        })
        write(os.path.join(folder, "02-beta.md"), {
            "title": '"test: beta"', "labels": ["area/api"], "parent": f'"#{root}"',
            "status": "In Progress", "priority": "low", "assignees": [], "blocked_by": ['"01-alpha.md"'], "issue": "",
        }, SECTIONS + "\nSee #ref:01-alpha.sub/01-alpha-child.md.\n")

        # Plan and apply the new tree.
        code, out = run.script("plan", folder)
        run.expect("plan lists three creates", code == 0 and out.count("create ") == 3, out)
        code, out = run.script("apply", folder)
        run.expect("apply of new drafts succeeds", code == 0, out)
        tree = issues.Tree(folder)
        alpha, child, beta = (draft.issue for draft in tree.walk())
        created += [number for number in (alpha, child, beta) if number]

        # Check the new issues on GitHub.
        a, c, b = run.remote(alpha), run.remote(child), run.remote(beta)
        me = issues.gh("api", "user", "--jq", ".login")
        run.expect("alpha is under the root", a.parent == root, a.parent)
        run.expect("child is under alpha", c.parent == alpha, c.parent)
        run.expect("beta is under the root", b.parent == root, b.parent)
        run.expect("board fields of alpha", (a.status, a.priority) == ("Todo", "high"), (a.status, a.priority))
        run.expect("board fields of beta", (b.status, b.priority) == ("In Progress", "low"), (b.status, b.priority))
        run.expect("labels of beta", b.labels == ["area/api"], b.labels)
        run.expect("@me assigns the gh user", c.assignees == [me], c.assignees)
        run.expect("beta is blocked by alpha", b.blocked_by == [f"{run.repo}#{alpha}"], b.blocked_by)
        run.expect("the #ref resolves", f"See #{child}." in b.body, b.body)

        # A second plan finds nothing to do.
        code, out = run.script("plan", folder)
        run.expect("plan after apply has no changes", code == 0 and "no changes" in out, out)

        # Export the tree.
        exported = os.path.join(work, "export")
        code, out = run.script("export", str(root), exported)
        top = out.strip().splitlines()[-1]
        run.expect("export succeeds", code == 0 and os.path.isdir(top), out)
        alpha_file = os.path.join(top, "01-alpha.md")
        beta_file = os.path.join(top, "02-beta.md")
        child_file = os.path.join(top, "01-alpha.sub", "01-alpha-child.md")
        exported_beta = issues.Draft(beta_file, "02", None)
        run.expect("export writes the blocker", exported_beta.blocked_by == [f"#{alpha}"], exported_beta.blocked_by)
        code, out = run.script("plan", top)
        run.expect("plan of a fresh export has no changes", code == 0 and "no changes" in out, out)

        # Move the child to beta, rename beta, swap labels, and change the body.
        moved = os.path.join(top, "02-beta.sub", "01-alpha-child.md")
        os.makedirs(os.path.dirname(moved))
        shutil.move(child_file, moved)
        os.rmdir(os.path.dirname(child_file))
        edit(moved, parent='"../02-beta.md"', blocked_by='["../01-alpha.md"]')
        edit(beta_file, title='"test: beta renamed"', labels="[kind/bug]", blocked_by="[]", status="Todo")
        with open(beta_file, "a", encoding="utf-8") as out_file:
            out_file.write("\nOne more line.\n")

        # Clear the priority of alpha, and close it, now that it is empty. A closed issue is `Done` on the board.
        edit(alpha_file, priority="", status="Done", state="closed")

        # Plan and apply the changes.
        code, out = run.script("plan", top)
        for kind in ("move", "title", "labels", "body", "status", "priority", "block", "unblock", "close"):
            run.expect(f"plan lists a {kind}", any(line.startswith(kind + " ") for line in out.splitlines()), out)
        order = [line.split()[0] for line in out.splitlines()]
        run.expect("plan closes last", order and order[-1] == "close", order)
        code, out = run.script("apply", top)
        run.expect("apply of the changes succeeds", code == 0, out)
        run.expect("apply leaves no differences", "differs from the drafts" not in out, out)

        # Check the changes on GitHub.
        a, c, b = run.remote(alpha), run.remote(child), run.remote(beta)
        run.expect("child moved to beta", c.parent == beta, c.parent)
        run.expect("beta renamed", b.title == "test: beta renamed", b.title)
        run.expect("beta labels swapped", b.labels == ["kind/bug"], b.labels)
        run.expect("beta body changed", b.body.endswith("One more line."), b.body[-60:])
        run.expect("beta status changed", b.status == "Todo", b.status)
        run.expect("alpha priority cleared", a.priority == "", a.priority)
        run.expect("alpha closed", a.state == "closed", a.state)
        run.expect("beta unblocked", b.blocked_by == [], b.blocked_by)
        run.expect("child blocked by alpha", c.blocked_by == [f"{run.repo}#{alpha}"], c.blocked_by)
        code, out = run.script("plan", top)
        run.expect("plan after apply of changes has no changes", code == 0 and "no changes" in out, out)

        # Change beta on GitHub behind the drafts, and change it in the drafts too.
        issues.gh("issue", "edit", str(beta), "--repo", run.repo, "--title", "test: beta changed elsewhere")
        edit(beta_file, priority="high")
        code, out = run.script("plan", top)
        run.expect("plan reports the conflict", code != 0 and f"conflict #{beta}" in out, out)
        code, out = run.script("apply", top)
        b = run.remote(beta)
        run.expect("apply refuses a conflict", code != 0 and "conflicts" in out, out)
        run.expect("apply wrote nothing on a conflict", b.priority == "low" and b.title == "test: beta changed elsewhere", (b.priority, b.title))

        # Reopen alpha from the drafts.
        edit(alpha_file, state="open", status="In Progress", updated=a.updated)
        edit(beta_file, title='"test: beta changed elsewhere"', priority="low", updated=b.updated)
        code, out = run.script("apply", top)
        a = run.remote(alpha)
        run.expect("apply reopens alpha", code == 0 and a.state == "open", out)

        # If the board closes an issue at `Done`, apply reports the difference to the open draft.
        edit(beta_file, status="Done", updated=run.remote(beta).updated)
        code, out = run.script("apply", top)
        if run.remote(beta).state == "closed":
            run.expect("apply reports a difference that a board workflow causes", code == 0 and "differs from the drafts" in out, out)
        else:
            print("SKIP  apply reports a difference that a board workflow causes: the board does not close issues at Done")

        # The check refuses a reference to a draft that does not exist.
        edit(alpha_file, blocked_by='["99-missing.md"]')
        code, out = run.script("check", top)
        run.expect("check refuses a missing blocker draft", code != 0 and "99-missing.md" in out, out)

        check_rejections(run, work, root, alpha)
        resume(run, work, root)
    finally:
        # Close every issue of the run. The drafts hold each issue that the script created, also after an error.
        for number in sorted(set(created) | drafted_issues(work)):
            subprocess.run(["gh", "issue", "close", str(number), "--repo", run.repo], capture_output=True)
        shutil.rmtree(work, ignore_errors=True)

    print(f"\n{len(run.failures)} failures" if run.failures else "\nall passed")
    sys.exit(1 if run.failures else 0)


if __name__ == "__main__":
    main()
