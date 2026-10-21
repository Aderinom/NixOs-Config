#!/usr/bin/env python3
"""Checks issue drafts and creates them on GitHub with the gh CLI.

The drafts follow the layout of SKILL.md. The top folder is the folder with
the drafts of the first level. If its name starts with an issue number, as
in `123-<slug>.sub`, that issue is their parent.

    issues.py check  <folder> --repo <owner/repo> [--project <owner>/<number>]
    issues.py create <folder> --repo <owner/repo> [--project <owner>/<number>] [--keep]

The board is the project of the parent issue, or the one that `--project`
names. Each draft sets its Status on that board.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

TITLE = re.compile(r"^(?:(?P<component>[^:]+): )?(?:(?P<number>\d{2}(?:\.\d{2})*) )?(?P<text>\S.*)$")
FILE = re.compile(r"^(?P<prefix>\d{2})-[a-z0-9]+(?:-[a-z0-9]+)*\.md$")
SECTIONS = ("## Goal", "## Scope", "## Definition of done")
KEYS = ("title", "labels", "parent", "status", "issue")


class Draft:
    """One draft file, with its place in the tree."""

    def __init__(self, path, number, parent_ref):
        self.path = path
        self.number = number
        self.parent_ref = parent_ref
        self.children = []
        self.text = open(path, encoding="utf-8").read()
        self.meta, self.body = parse(self.text)

    @property
    def title(self):
        return self.meta.get("title", "")

    @property
    def labels(self):
        return self.meta.get("labels", [])

    @property
    def status(self):
        return self.meta.get("status", "")

    @property
    def issue(self):
        url = self.meta.get("issue", "")
        return int(url.rstrip("/").rsplit("/", 1)[-1]) if url else None


def parse(text):
    """Splits a draft into its front matter and its body."""
    match = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not match:
        return {}, text
    meta = {}
    for line in match.group(1).splitlines():
        key, _, value = line.partition(":")
        value = value.strip()
        if key.strip() == "labels":
            value = [label.strip() for label in value.strip("[]").split(",") if label.strip()]
        elif len(value) >= 2 and value[0] == value[-1] == '"':
            value = value[1:-1]
        meta[key.strip()] = value
    return meta, match.group(2).lstrip("\n")


def load(folder, prefix="", parent_ref=None):
    """Reads the drafts of a folder and of its `.sub` folders, in order."""
    drafts = []
    names = sorted(os.listdir(folder))
    for name in names:
        path = os.path.join(folder, name)
        if name.endswith(".md"):
            match = FILE.match(name)
            number = f"{prefix}{match.group('prefix')}" if match else f"{prefix}??"
            draft = Draft(path, number, parent_ref)
            sub = path[:-3] + ".sub"
            if os.path.isdir(sub):
                draft.children = load(sub, number + ".", f"../{name}")
            drafts.append(draft)
    return drafts


def core(title):
    """The text of a title, without the component prefix and the number."""
    text = re.sub(r"^[^:]+: ", "", title)
    return re.sub(r"^\d{2}(?:\.\d{2})* ", "", text).strip().lower()


def walk(drafts):
    for draft in drafts:
        yield draft
        yield from walk(draft.children)


def gh(*args):
    result = subprocess.run(["gh", *args], capture_output=True, text=True)
    if result.returncode != 0:
        # A board needs the project scope, which `gh auth login` does not grant.
        hint = "\nRun `gh auth refresh -s project`." if "INSUFFICIENT_SCOPES" in result.stderr else ""
        sys.exit(f"gh {' '.join(args[:3])} failed:\n{result.stderr}{hint}")
    return result.stdout.strip()


def graphql(query, **variables):
    args = ["api", "graphql", "-f", f"query={query}"]
    for key, value in variables.items():
        args += ["-F" if isinstance(value, int) else "-f", f"{key}={value}"]
    return json.loads(gh(*args))["data"]


class Board:
    """A GitHub project and its Status field."""

    FIELDS = "id title number field(name: \"Status\") { ... on ProjectV2SingleSelectField { id options { id name } } }"

    def __init__(self, project):
        self.id = project["id"]
        self.title = f"{project['title']} (#{project['number']})"
        field = project["field"] or {}
        self.field = field.get("id")
        self.options = {option["name"]: option["id"] for option in field.get("options", [])}

    @classmethod
    def of_issue(cls, repo, number):
        """The board of an issue, or None. Exits if the issue is on more than one board."""
        owner, name = repo.split("/")
        query = f"""query($owner: String!, $name: String!, $number: Int!) {{
          repository(owner: $owner, name: $name) {{ issue(number: $number) {{
            projectItems(first: 10) {{ nodes {{ project {{ {cls.FIELDS} }} }} }} }} }} }}"""
        nodes = graphql(query, owner=owner, name=name, number=number)["repository"]["issue"]["projectItems"]["nodes"]
        if len(nodes) > 1:
            sys.exit(f"#{number} is on more than one board. Pass --project <owner>/<number>.")
        return cls(nodes[0]["project"]) if nodes else None

    @classmethod
    def named(cls, spec):
        """The board `<owner>/<number>`, of an organization or of a user."""
        owner, _, number = spec.partition("/")
        for kind in ("organization", "user"):
            query = f"""query($owner: String!, $number: Int!) {{
              {kind}(login: $owner) {{ projectV2(number: $number) {{ {cls.FIELDS} }} }} }}"""
            result = subprocess.run(["gh", "api", "graphql", "-f", f"query={query}", "-f", f"owner={owner}", "-F", f"number={number}"], capture_output=True, text=True)
            if result.returncode == 0:
                return cls(json.loads(result.stdout)["data"][kind]["projectV2"])
        sys.exit(f"no board {spec}:\n{result.stderr}")

    def set_status(self, repo, number, status):
        """Adds the issue to the board, if it is not there yet, and sets its Status."""
        node = gh("api", f"repos/{repo}/issues/{number}", "--jq", ".node_id")
        # addProjectV2ItemById returns the existing item if a board workflow added the issue first.
        item = graphql(
            "mutation($project: ID!, $content: ID!) { addProjectV2ItemById(input: {projectId: $project, contentId: $content}) { item { id } } }",
            project=self.id, content=node,
        )["addProjectV2ItemById"]["item"]["id"]
        graphql(
            "mutation($project: ID!, $item: ID!, $field: ID!, $option: String!) { updateProjectV2ItemFieldValue(input: {projectId: $project, itemId: $item, fieldId: $field, value: {singleSelectOptionId: $option}}) { projectV2Item { id } } }",
            project=self.id, item=item, field=self.field, option=self.options[status],
        )


def top_parent(folder):
    """The number of the existing parent issue, from the name of the top folder."""
    match = re.match(r"^(\d+)-.*\.sub$", os.path.basename(os.path.normpath(folder)))
    return int(match.group(1)) if match else None


def check(folder, repo, project):
    """Returns the drafts, the board, and a list of problems."""
    problems = []
    drafts = load(folder)
    parent = top_parent(folder)
    expected_top = f"#{parent}" if parent else ""

    # Find the board.
    board = Board.named(project) if project else Board.of_issue(repo, parent) if parent else None
    if board and not board.field:
        problems.append(f"{board.title} has no Status field")

    for root, dirs, files in os.walk(folder):
        for name in files:
            path = os.path.join(root, name)
            if not FILE.match(name):
                problems.append(f"{path}: the name is not `NN-<slug>.md`")
        for name in dirs:
            if not name.endswith(".sub") or not os.path.isfile(os.path.join(root, name[:-4] + ".md")):
                problems.append(f"{os.path.join(root, name)}: a folder without a draft of the same name")

    labels = {item["name"] for item in json.loads(gh("label", "list", "--repo", repo, "--limit", "1000", "--json", "name"))}
    titles = {}
    for draft in walk(drafts):
        where = draft.path
        for key in KEYS:
            if key not in draft.meta:
                problems.append(f"{where}: no `{key}` in the front matter")
        match = TITLE.match(draft.title)
        if not match:
            problems.append(f"{where}: the title is not `<component>: [<number>] <text>`: {draft.title}")
        elif match.group("number") not in (None, draft.number):
            problems.append(f"{where}: the title has number {match.group('number')}, the file needs {draft.number}")
        text = core(draft.title)
        if text in titles:
            problems.append(f"{where}: the same title as {titles[text]}")
        titles[text] = where
        expected = draft.parent_ref if draft.parent_ref else expected_top
        if draft.meta.get("parent", "") != expected:
            problems.append(f"{where}: the parent is `{draft.meta.get('parent', '')}`, expected `{expected}`")
        for label in draft.labels:
            if label not in labels:
                problems.append(f"{where}: the label `{label}` does not exist in {repo}")
        for section in SECTIONS:
            if section not in draft.body:
                problems.append(f"{where}: no `{section}` section")
        if board and draft.status not in board.options:
            problems.append(f"{where}: the status `{draft.status}` is not one of {', '.join(board.options)} on {board.title}")
        elif not board and draft.status:
            problems.append(f"{where}: a status, but no board. Pass --project <owner>/<number>.")

    # Number every issue of one level, or none.
    for level in [drafts, *(draft.children for draft in walk(drafts))]:
        numbered = [draft for draft in level if TITLE.match(draft.title) and TITLE.match(draft.title).group("number")]
        if numbered and len(numbered) != len(level):
            problems.append(f"{os.path.dirname(level[0].path)}: some titles have a number and some do not")

    if parent:
        existing = json.loads(gh("api", f"repos/{repo}/issues/{parent}/sub_issues", "--jq", "[.[] | .title]"))
        known = {core(title) for title in existing}
        for draft in drafts:
            if not draft.issue and core(draft.title) in known:
                problems.append(f"{draft.path}: #{parent} already has a sub-issue with this title")
    return drafts, board, problems


def print_tree(drafts, depth=0):
    for draft in drafts:
        state = f"#{draft.issue}" if draft.issue else "new"
        status = f"  {draft.status}" if draft.status else ""
        print(f"{'  ' * depth}{draft.number}  {draft.title}  [{', '.join(draft.labels)}]{status}  {state}")
        print_tree(draft.children, depth + 1)


def create(drafts, repo, parent, board):
    """Creates each draft, then its sub-issues, attaches each one to its parent, and sets its Status."""
    for draft in drafts:
        number = draft.issue
        if number is None:
            with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False) as body:
                body.write(draft.body)
            args = ["issue", "create", "--repo", repo, "--title", draft.title, "--body-file", body.name]
            for label in draft.labels:
                args += ["--label", label]
            url = gh(*args)
            os.unlink(body.name)
            number = int(url.rstrip("/").rsplit("/", 1)[-1])
            # The sub-issue API takes the internal id, not the number.
            if parent:
                internal = gh("api", f"repos/{repo}/issues/{number}", "--jq", ".id")
                gh("api", f"repos/{repo}/issues/{parent}/sub_issues", "-X", "POST", "-F", f"sub_issue_id={internal}")
            if board:
                board.set_status(repo, number, draft.status)
            draft.text = re.sub(r"(?m)^issue:.*$", f"issue: {url}", draft.text, count=1)
            draft.meta["issue"] = url
            with open(draft.path, "w", encoding="utf-8") as out:
                out.write(draft.text)
            print(f"created #{number}  {draft.title}" + (f"  under #{parent}" if parent else ""))
        create(draft.children, repo, number, board)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["check", "create"])
    parser.add_argument("folder", help="the folder with the drafts of the first level")
    parser.add_argument("--repo", required=True, help="owner/repo")
    parser.add_argument("--project", help="the board as <owner>/<number>, if the parent issue is on none or on several")
    parser.add_argument("--keep", action="store_true", help="keep the drafts after `create`")
    args = parser.parse_args()

    drafts, board, problems = check(args.folder, args.repo, args.project)
    if problems:
        print("\n".join(problems), file=sys.stderr)
        sys.exit(1)
    if args.command == "check":
        if board:
            print(f"board: {board.title}")
        print_tree(drafts)
        return

    create(drafts, args.repo, top_parent(args.folder), board)
    print()
    print_tree(drafts)
    if not args.keep:
        shutil.rmtree(args.folder)
        print(f"\ndeleted {args.folder}")
        # The folder that holds the drafts goes too, once it is empty.
        outer = os.path.dirname(os.path.normpath(args.folder))
        if outer and not os.listdir(outer):
            os.rmdir(outer)
            print(f"deleted {outer}")


if __name__ == "__main__":
    main()
