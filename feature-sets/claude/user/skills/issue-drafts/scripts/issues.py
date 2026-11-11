#!/usr/bin/env python3
"""Keeps a folder of issue drafts in sync with GitHub, with the gh CLI.

The drafts follow the layout of SKILL.md. The top folder holds the drafts of
the first level.

If the name of the top folder starts with an issue number, as in
`123-<slug>.sub`, that issue is the parent of the first level.

    issues.py check  <folder> --repo <owner/repo> [--project <owner>/<number>]
    issues.py plan   <folder> --repo <owner/repo> [--project <owner>/<number>]
    issues.py apply  <folder> --repo <owner/repo> [--project <owner>/<number>]
    issues.py export <issue> <out folder> --repo <owner/repo> [--project <owner>/<number>]

`check` and `plan` write nothing. `apply` makes the changes that `plan`
lists.

`export` writes the open sub-issues of an issue as drafts.

The board is the project of the parent issue, or the one that `--project`
names.
"""

from __future__ import annotations

import argparse
import difflib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass
from typing import Callable

TITLE = re.compile(r"^(?:(?P<component>[^:]+): )?(?:(?P<number>\d{2}(?:\.\d{2})*) )?(?P<text>\S.*)$")
FILE = re.compile(r"^(?P<prefix>\d{2})-[a-z0-9]+(?:-[a-z0-9]+)*\.md$")
URL = re.compile(r"^https://github\.com/(?P<repo>[\w.-]+/[\w.-]+)/issues/(?P<number>\d+)/?$")
REF = re.compile(r"#ref:(\S+?\.md)")
BLOCKER = re.compile(r"^(?:(?P<repo>[\w.-]+/[\w.-]+))?#(?P<number>\d+)$")
SECTIONS = ("## Goal", "## Scope", "## Definition of done")
KEYS = ("title", "labels", "parent", "status", "issue")
KNOWN = ("title", "labels", "parent", "status", "priority", "assignees", "blocked_by", "state", "updated", "issue")
LISTS = ("labels", "assignees", "blocked_by")
# The most items that the script reads of one list of an issue, such as its labels.
LIMIT = 100
# Seconds to wait for board workflows after a change. On a test board, a default workflow closed an issue 2 seconds after the Status `Done`.
WORKFLOW_DELAY = 5


class Draft:
    """One draft file, with its place in the tree.

    For an existing issue, a missing key leaves that part of the issue as it is.
    """

    def __init__(self, path, number, parent_ref):
        self.path = path
        self.number = number
        self.parent_ref = parent_ref
        self.children = []
        with open(path, encoding="utf-8") as source:
            self.text = source.read()
        self.meta, self.body, self.unread = parse(self.text)

    @property
    def title(self):
        return self.meta.get("title", "")

    @property
    def labels(self):
        """The labels, or None to leave them as they are."""
        return self.meta.get("labels")

    @property
    def assignees(self):
        """The assignees, or None to leave them as they are."""
        return self.meta.get("assignees")

    @property
    def blocked_by(self):
        """The blockers, or None to leave them as they are."""
        return self.meta.get("blocked_by")

    @property
    def status(self):
        """The Status on the board, "" to clear it, or None to leave it as it is."""
        return self.meta.get("status")

    @property
    def priority(self):
        """The Priority on the board, "" to clear it, or None to leave it as it is."""
        return self.meta.get("priority")

    @property
    def state(self):
        """`open`, `closed`, or None to leave the state as it is."""
        return self.meta.get("state") or None

    @property
    def updated(self):
        return self.meta.get("updated", "")

    @property
    def issue(self):
        """The number of the issue, or None if the draft has no valid issue URL."""
        match = URL.match(self.meta.get("issue", ""))
        if not match:
            return None

        return int(match.group("number"))

    def set_meta(self, key, value):
        """Writes `key: value` into the front matter of the file."""
        match = re.match(r"^(---\n)(.*?)(\n---\n)(.*)$", self.text, re.S)
        line = f"{key}: {value}"
        front = match.group(2)

        # Replace the line of the key, or add one at the end of the front matter.
        pattern = re.compile(rf"(?m)^{re.escape(key)}:.*$")
        if pattern.search(front):
            front = pattern.sub(lambda _: line, front, count=1)
        else:
            front = f"{front}\n{line}"

        # Write the file.
        self.text = match.group(1) + front + match.group(3) + match.group(4)
        self.meta, self.body, self.unread = parse(self.text)
        with open(self.path, "w", encoding="utf-8") as out:
            out.write(self.text)


def parse(text):
    """Splits a draft into its front matter, its body, and the front matter lines that it cannot read.

    A list holds its items on one line, as in `[a, "b, c"]`. A quoted value is a JSON string.
    """

    def unquote(value):
        if len(value) < 2 or value[0] != '"' or value[-1] != '"':
            return value
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value[1:-1]

    def split(value):
        """The items of a list. A comma inside quotes does not split."""
        items = []
        current = ""
        quoted = escaped = False
        for char in value[1:-1]:
            if quoted and escaped:
                escaped = False
            elif quoted and char == "\\":
                escaped = True
            elif char == '"':
                quoted = not quoted
            elif char == "," and not quoted:
                items.append(current)
                current = ""
                continue
            current += char
        items.append(current)
        return [unquote(item.strip()) for item in items if item.strip()]

    match = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not match:
        return {}, text, []

    # Read each line of the front matter. Keep the lines that do not fit the format.
    meta = {}
    unread = []
    for line in match.group(1).splitlines():
        key, colon, value = line.partition(":")
        key, value = key.strip(), value.strip()
        if not line.strip():
            continue
        if not colon or line[0].isspace() or key not in KNOWN:
            unread.append(line)
        elif key in LISTS and not value:
            meta[key] = []
        elif key in LISTS and value.startswith("[") and value.endswith("]"):
            meta[key] = split(value)
        elif key in LISTS:
            unread.append(line)
        else:
            meta[key] = unquote(value)
    return meta, match.group(2).lstrip("\n"), unread


def core(title):
    """The text of a title, without the component prefix and the number."""
    text = re.sub(r"^[^:]+: ", "", title)
    return re.sub(r"^\d{2}(?:\.\d{2})* ", "", text).strip().lower()


def slug(title):
    """The file name of a title: lowercase words joined by `-`, at most 60 characters."""
    words = re.sub(r"[^a-z0-9]+", "-", core(title)).strip("-").split("-")

    # Add words while they fit.
    out = ""
    for word in words:
        if out and len(out) + len(word) + 1 > 60:
            break
        out = f"{out}-{word}" if out else word
    return out


class Tree:
    """The drafts of a folder, with the parent issue of the first level."""

    def __init__(self, folder):

        def load(folder, prefix="", parent_ref=None):
            """Reads the drafts of a folder and of its `.sub` folders, in order."""
            drafts = []
            for name in sorted(os.listdir(folder)):
                path = os.path.join(folder, name)
                if not name.endswith(".md"):
                    continue
                match = FILE.match(name)
                number = f"{prefix}{match.group('prefix')}" if match else f"{prefix}??"
                draft = Draft(path, number, parent_ref)
                sub = path[:-3] + ".sub"
                if os.path.isdir(sub):
                    draft.children = load(sub, number + ".", f"../{name}")
                drafts.append(draft)
            return drafts

        self.folder = folder
        self.drafts = load(folder)
        self.by_path = {os.path.abspath(draft.path): draft for draft in self.walk()}

        # The name of the top folder gives the parent of the first level.
        match = re.match(r"^(\d+)-.*\.sub$", os.path.basename(os.path.normpath(folder)))
        self.parent = int(match.group(1)) if match else None

    def walk(self, drafts=None):
        """Every draft, each parent before its children."""
        for draft in self.drafts if drafts is None else drafts:
            yield draft
            yield from self.walk(draft.children)

    def target(self, draft, relative):
        """The draft at `relative`, a path from the folder of `draft`, or None."""
        path = os.path.abspath(os.path.join(os.path.dirname(draft.path), relative))
        return self.by_path.get(path)

    def parent_of(self, draft):
        """The issue number of the parent of `draft`, or None if that issue does not exist yet."""
        if draft.parent_ref is None:
            return self.parent

        parent = self.target(draft, draft.parent_ref)
        return parent.issue

    def body_of(self, draft):
        """The body of `draft`, with each `#ref:<path>` of a draft with issue replaced by `#<number>`."""

        def replace(match):
            target = self.target(draft, match.group(1))
            known = target is not None and target.issue is not None
            reference = f"#{target.issue}" if known else match.group(0)
            return reference

        return REF.sub(replace, draft.body)

    def blockers_of(self, draft, repo):
        """The blockers of `draft` as `owner/repo#n`, and the tree numbers of the blocker drafts without issue."""
        keys = []
        pending = []
        for entry in draft.blocked_by or []:
            match = BLOCKER.match(entry)
            target = None if match else self.target(draft, entry)
            if match:
                keys.append(f"{match.group('repo') or repo}#{match.group('number')}")
            elif target.issue:
                keys.append(f"{repo}#{target.issue}")
            else:
                pending.append(target.number)
        return keys, pending


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


def issue_id(repo, number):
    """The internal id of an issue, which the sub-issue and dependency APIs take."""
    return int(gh("api", f"repos/{repo}/issues/{number}", "--jq", ".id"))


@dataclass
class Remote:
    """The state of an issue on GitHub."""

    number: int
    title: str
    body: str
    state: str
    updated: str
    labels: list[str]
    assignees: list[str]
    parent: int | None
    blocked_by: list[str]
    status: str
    priority: str
    children: list[int]

    QUERY = f"""query($owner: String!, $name: String!, $number: Int!) {{
      repository(owner: $owner, name: $name) {{ issue(number: $number) {{
        number title body state updatedAt
        labels(first: {LIMIT}) {{ totalCount nodes {{ name }} }}
        assignees(first: {LIMIT}) {{ totalCount nodes {{ login }} }}
        parent {{ number }}
        blockedBy(first: {LIMIT}) {{ totalCount nodes {{ number repository {{ nameWithOwner }} }} }}
        subIssues(first: {LIMIT}) {{ totalCount nodes {{ number state }} }}
        projectItems(first: {LIMIT}) {{ totalCount nodes {{
          project {{ id }}
          status: fieldValueByName(name: "Status") {{ ... on ProjectV2ItemFieldSingleSelectValue {{ name }} }}
          priority: fieldValueByName(name: "Priority") {{ ... on ProjectV2ItemFieldSingleSelectValue {{ name }} }} }} }} }} }} }}"""

    @classmethod
    def fetch(cls, repo, number, board):
        """The state of issue `number`. The board fields come from `board`, if it is set."""
        owner, name = repo.split("/")
        issue = graphql(cls.QUERY, owner=owner, name=name, number=number)["repository"]["issue"]
        if issue is None:
            sys.exit(f"#{number} is no issue of {repo}. It is missing, transferred, or a pull request.")

        # Refuse a list that the query cannot read in full, because a diff of part of it is wrong.
        for key in ("labels", "assignees", "blockedBy", "subIssues", "projectItems"):
            if issue[key]["totalCount"] > len(issue[key]["nodes"]):
                sys.exit(f"#{number} has more than {LIMIT} {key}. The script reads at most {LIMIT}.")

        # Take the fields of this board.
        items = [node for node in issue["projectItems"]["nodes"] if board and node["project"]["id"] == board.id]
        item = items[0] if items else {}
        remote = cls(
            number=issue["number"],
            title=issue["title"],
            body=normalize(issue["body"] or ""),
            state=issue["state"].lower(),
            updated=issue["updatedAt"],
            labels=[node["name"] for node in issue["labels"]["nodes"]],
            assignees=[node["login"] for node in issue["assignees"]["nodes"]],
            parent=(issue["parent"] or {}).get("number"),
            blocked_by=[f"{node['repository']['nameWithOwner']}#{node['number']}" for node in issue["blockedBy"]["nodes"]],
            status=(item.get("status") or {}).get("name", ""),
            priority=(item.get("priority") or {}).get("name", ""),
            children=[node["number"] for node in issue["subIssues"]["nodes"] if node["state"] == "OPEN"],
        )
        return remote


def normalize(body):
    """A body with Unix line ends and no whitespace at its ends."""
    return body.replace("\r\n", "\n").strip()


class Board:
    """A GitHub project and its Status and Priority fields."""

    SELECT = "... on ProjectV2SingleSelectField { id options { id name } }"
    FIELDS = f"id title number status: field(name: \"Status\") {{ {SELECT} }} priority: field(name: \"Priority\") {{ {SELECT} }}"

    def __init__(self, project):
        self.id = project["id"]
        self.title = f"{project['title']} (#{project['number']})"
        self.status = Field("Status", project["status"])
        self.priority = Field("Priority", project["priority"])

    @classmethod
    def of_issue(cls, repo, number):
        """The board of an issue, or None. Exits if the issue is on more than one board."""
        owner, name = repo.split("/")
        query = f"""query($owner: String!, $name: String!, $number: Int!) {{
          repository(owner: $owner, name: $name) {{ issue(number: $number) {{
            projectItems(first: 10) {{ nodes {{ project {{ {cls.FIELDS} }} }} }} }} }} }}"""
        nodes = graphql(query, owner=owner, name=name, number=number)["repository"]["issue"]["projectItems"]["nodes"]

        # Take the one board. Several boards need `--project`.
        if len(nodes) > 1:
            sys.exit(f"#{number} is on more than one board. Pass --project <owner>/<number>.")
        if not nodes:
            return None

        return cls(nodes[0]["project"])

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

    def item(self, repo, number):
        """The item id of the issue on the board. Adds the issue if it is not there yet."""
        node = gh("api", f"repos/{repo}/issues/{number}", "--jq", ".node_id")

        # A board workflow can add the issue first. The add then fails, and the item already exists.
        item = self.add(node) or self.item_of(repo, number)
        return item

    def add(self, node):
        """Adds the content `node` to the board and returns the item id, or None if the board holds it already."""
        query = "mutation($project: ID!, $content: ID!) { addProjectV2ItemById(input: {projectId: $project, contentId: $content}) { item { id } } }"
        result = subprocess.run(
            ["gh", "api", "graphql", "-f", f"query={query}", "-f", f"project={self.id}", "-f", f"content={node}"],
            capture_output=True, text=True,
        )

        # If the board holds the item already, the caller looks it up. Any other error stops the run.
        if result.returncode != 0 and "Content already exists" in result.stderr:
            return None
        if result.returncode != 0:
            sys.exit(f"gh api graphql failed:\n{result.stderr}")

        return json.loads(result.stdout)["data"]["addProjectV2ItemById"]["item"]["id"]

    def item_of(self, repo, number):
        """The id of the item of issue `number` on this board."""
        owner, name = repo.split("/")
        query = f"""query($owner: String!, $name: String!, $number: Int!) {{
          repository(owner: $owner, name: $name) {{ issue(number: $number) {{
            projectItems(first: {LIMIT}) {{ nodes {{ id project {{ id }} }} }} }} }} }}"""
        nodes = graphql(query, owner=owner, name=name, number=number)["repository"]["issue"]["projectItems"]["nodes"]
        items = [node["id"] for node in nodes if node["project"]["id"] == self.id]
        if not items:
            sys.exit(f"#{number} is not on {self.title}, but adding it failed with `Content already exists`")

        return items[0]


class Field:
    """A single-select field of a board, with its options by name."""

    def __init__(self, name, field):
        field = field or {}
        self.name = name
        self.id = field.get("id")
        self.options = {option["name"]: option["id"] for option in field.get("options", [])}

    def set(self, board, item, option):
        """Sets the field of `item` to `option`. An empty `option` clears the field."""
        if not option:
            graphql(
                "mutation($project: ID!, $item: ID!, $field: ID!) { clearProjectV2ItemFieldValue(input: {projectId: $project, itemId: $item, fieldId: $field}) { projectV2Item { id } } }",
                project=board.id, item=item, field=self.id,
            )
            return

        graphql(
            "mutation($project: ID!, $item: ID!, $field: ID!, $option: String!) { updateProjectV2ItemFieldValue(input: {projectId: $project, itemId: $item, fieldId: $field, value: {singleSelectOptionId: $option}}) { projectV2Item { id } } }",
            project=board.id, item=item, field=self.id, option=self.options[option],
        )


def check(tree, repo, board):
    """Returns the problems of the drafts in `tree`."""

    def check_draft(draft):
        """Returns the problems of one draft."""
        problems = []
        where = draft.path
        new = not draft.meta.get("issue")

        # Check the front matter, the issue URL, and the title.
        for line in draft.unread:
            problems.append(f"{where}: cannot read `{line}`. Write `key: value` with a known key, and a list as `[a, b]` on one line.")
        for key in KEYS:
            if key not in draft.meta:
                problems.append(f"{where}: no `{key}` in the front matter")
        url = URL.match(draft.meta.get("issue", ""))
        if not new and not url:
            problems.append(f"{where}: the issue `{draft.meta['issue']}` is not `https://github.com/<owner>/<repo>/issues/<n>`")
        elif url and url.group("repo") != repo:
            problems.append(f"{where}: the issue is in {url.group('repo')}, not in {repo}")
        match = TITLE.match(draft.title)
        if not match:
            problems.append(f"{where}: the title is not `<component>: [<number>] <text>`: {draft.title}")
        elif match.group("number") not in (None, draft.number):
            problems.append(f"{where}: the title has number {match.group('number')}, the file needs {draft.number}")
        if draft.state not in (None, "open", "closed"):
            problems.append(f"{where}: the state `{draft.state}` is not `open` or `closed`")

        # Check the parent and the labels.
        expected = draft.parent_ref if draft.parent_ref else expected_top
        if draft.meta.get("parent", "") != expected:
            problems.append(f"{where}: the parent is `{draft.meta.get('parent', '')}`, expected `{expected}`")
        for label in draft.labels or []:
            if label not in labels:
                problems.append(f"{where}: the label `{label}` does not exist")

        # A new issue needs the sections. An existing issue keeps the body it has, but an empty body would erase it.
        for section in SECTIONS:
            if new and section not in draft.body:
                problems.append(f"{where}: no `{section}` section")
        if not new and not draft.body.strip():
            problems.append(f"{where}: an empty body would erase the body of the issue")

        # Check the board fields. A new issue needs a Status, so it does not get lost on the board.
        for field, value in ((board.status, draft.status), (board.priority, draft.priority)) if board else ():
            required = new and field.name == "Status"
            if value and not field.id:
                problems.append(f"{where}: a {field.name.lower()}, but {board.title} has no {field.name} field")
            elif value and value not in field.options:
                problems.append(f"{where}: the {field.name.lower()} `{value}` is not one of {', '.join(field.options)} on {board.title}")
            elif required and not value:
                problems.append(f"{where}: a new issue needs a status, one of {', '.join(field.options)}")
        if not board and (draft.status or draft.priority):
            problems.append(f"{where}: a status or a priority, but no board. Pass --project <owner>/<number>.")

        # Check the references to other drafts.
        for path in REF.findall(draft.body):
            if not tree.target(draft, path):
                problems.append(f"{where}: `#ref:{path}` names no draft")
        for entry in draft.blocked_by or []:
            if not BLOCKER.match(entry) and not tree.target(draft, entry):
                problems.append(f"{where}: the blocker `{entry}` is not `#<n>`, `<owner>/<repo>#<n>`, or the path of a draft")
        return problems

    problems = []
    expected_top = f"#{tree.parent}" if tree.parent else ""
    if board and not board.status.id:
        problems.append(f"{board.title} has no Status field")

    # Check the names of the files and the folders.
    for root, dirs, files in os.walk(tree.folder):
        for name in files:
            if not FILE.match(name):
                problems.append(f"{os.path.join(root, name)}: the name is not `NN-<slug>.md`")
        for name in dirs:
            if not name.endswith(".sub") or not os.path.isfile(os.path.join(root, name[:-4] + ".md")):
                problems.append(f"{os.path.join(root, name)}: a folder without a draft of the same name")

    # Check each draft, and find titles and issues that two drafts share.
    labels = {item["name"] for item in json.loads(gh("label", "list", "--repo", repo, "--limit", "1000", "--json", "name"))}
    titles = {}
    issues = {}
    for draft in tree.walk():
        problems += check_draft(draft)
        text = core(draft.title)
        if text in titles:
            problems.append(f"{draft.path}: the same title as {titles[text]}")
        titles[text] = draft.path
        if draft.issue and draft.issue in issues:
            problems.append(f"{draft.path}: the same issue as {issues[draft.issue]}")
        issues[draft.issue] = draft.path

    # Number every issue of one level, or none.
    for level in [tree.drafts, *(draft.children for draft in tree.walk())]:
        numbered = [draft for draft in level if TITLE.match(draft.title) and TITLE.match(draft.title).group("number")]
        if numbered and len(numbered) != len(level):
            problems.append(f"{os.path.dirname(level[0].path)}: some titles have a number and some do not")

    # A new draft of the first level must not repeat a sub-issue of the parent.
    if tree.parent:
        existing = gh("api", "--paginate", f"repos/{repo}/issues/{tree.parent}/sub_issues", "--jq", ".[].title").splitlines()
        known = {core(title) for title in existing}
        for draft in tree.drafts:
            if not draft.issue and core(draft.title) in known:
                problems.append(f"{draft.path}: #{tree.parent} already has a sub-issue with this title")
    return problems


@dataclass
class Change:
    """One change that `apply` makes on GitHub, in the order of its step.

    `touches` lists the issues whose `updatedAt` the change moves.
    """

    step: int
    draft: Draft
    text: str
    run: Callable[[], None]
    touches: tuple[int, ...] = ()


CREATE, REOPEN, UNBLOCK, UPDATE, MOVE, FIELDS, BLOCK, CLOSE = range(8)


class Sync:
    """Compares a tree of drafts with GitHub, and makes the changes."""

    def __init__(self, tree, repo, board):
        self.tree = tree
        self.repo = repo
        self.board = board
        self.me = None

    def plan(self):
        """Returns the changes in the order of `apply`, and the conflicts."""

        def order(change):
            # Close the deepest issues first, so that a parent closes after its children.
            depth = -change.draft.number.count(".") if change.step == CLOSE else 0
            return change.step, depth

        changes = []
        conflicts = []
        for draft in self.tree.walk():
            if draft.issue is None:
                changes.append(self.create(draft))
                continue

            remote = Remote.fetch(self.repo, draft.issue, self.board)
            if draft.updated and remote.updated != draft.updated:
                conflicts.append(f"#{draft.issue}: changed on GitHub at {remote.updated}, the draft has {draft.updated}")
            changes += self.compare(draft, remote)
        changes.sort(key=order)
        return changes, conflicts

    def apply(self):
        """Makes all changes. Stops before the first write if there is a conflict."""
        changes, conflicts = self.plan()
        if conflicts:
            sys.exit("conflicts, export again and redo the changes:\n" + "\n".join(conflicts))

        # Create the new issues first, so that every draft has an issue for the other changes.
        for change in changes:
            if change.step == CREATE:
                print(change.text)
                change.run()

        # Compare again, now with the numbers of the new issues. Record each change for the conflict check of the next run.
        changes, _ = self.plan()
        for change in changes:
            print(change.text)
            change.run()
            self.refresh(change.touches)

        # If a change can start a board workflow, wait for it. Workflows react within a few seconds.
        if any(change.step in (FIELDS, REOPEN, CLOSE) for change in changes):
            time.sleep(WORKFLOW_DELAY)

        # Compare once more. A change by a board workflow, or by a person, shows up as a difference or a conflict.
        left, conflicts = self.plan()
        if left or conflicts:
            print("\nafter apply, GitHub differs from the drafts. A board workflow or a person changed it:")
            for line in [change.text for change in left] + [f"conflict {conflict}" for conflict in conflicts]:
                print(f"  {line}")

    def create(self, draft):
        """The change that creates the issue of a new draft."""
        parent = self.tree.parent_of(draft)
        keys, pending = self.tree.blockers_of(draft, self.repo)
        where = f"#{parent}" if parent else f"new {self.tree.target(draft, draft.parent_ref).number}" if draft.parent_ref else "the top"
        fields = ", ".join(value for value in (draft.status, draft.priority) if value)
        blockers = [short(key, self.repo) for key in keys] + [f"new {number}" for number in pending]
        blocked = f"  blocked by {', '.join(blockers)}" if blockers else ""
        text = f"create   {draft.number}  {draft.title}  under {where}  [{fields}]{blocked}"

        def run():
            # Create the issue.
            args = ["issue", "create", "--repo", self.repo, "--title", draft.title]
            for label in draft.labels or []:
                args += ["--label", label]
            for assignee in draft.assignees or []:
                args += ["--assignee", assignee]
            url = self.with_body(draft, args)
            draft.set_meta("issue", url)

            # Attach it to its parent, which the tree order created before.
            parent = self.tree.parent_of(draft)
            if parent:
                gh("api", f"repos/{self.repo}/issues/{parent}/sub_issues", "-X", "POST", "-F", f"sub_issue_id={issue_id(self.repo, draft.issue)}")
            self.refresh((draft.issue, parent))

        return Change(CREATE, draft, text, run)

    def compare(self, draft, remote):
        """The changes that make `remote` match `draft`. A missing key in the draft gives no change."""

        def signed(added, removed):
            return " ".join([f"+{item}" for item in added] + [f"-{item}" for item in removed])

        def diffstat(old, new):
            """The count of added and removed lines, as `+a -b lines`."""
            lines = list(difflib.ndiff(old.splitlines(), new.splitlines()))
            added = sum(line.startswith("+ ") for line in lines)
            removed = sum(line.startswith("- ") for line in lines)
            return f"+{added} -{removed} lines"

        def local(key):
            """The number of `key` as a one-item tuple if the issue is in the repository, else an empty tuple."""
            other, _, blocker = key.partition("#")
            numbers = (int(blocker),) if other == self.repo else ()
            return numbers

        changes = []
        number = remote.number
        nearby = tuple(n for n in (number, remote.parent) if n)

        # Reopen early, so that the other changes reach an open issue.
        if draft.state == "open" and remote.state == "closed":
            changes.append(Change(REOPEN, draft, f"reopen   #{number}", lambda: gh("issue", "reopen", str(number), "--repo", self.repo), nearby))

        # The title.
        if draft.title != remote.title:
            text = f"title    #{number}  {remote.title!r} → {draft.title!r}"
            changes.append(Change(UPDATE, draft, text, lambda: gh("issue", "edit", str(number), "--repo", self.repo, "--title", draft.title), (number,)))

        # The body.
        body = normalize(self.tree.body_of(draft))
        if body != remote.body:
            changes.append(Change(UPDATE, draft, f"body     #{number}  {diffstat(remote.body, body)}", lambda: self.with_body(draft, ["issue", "edit", str(number), "--repo", self.repo]), (number,)))

        # The labels.
        if draft.labels is not None:
            added = [label for label in draft.labels if label not in remote.labels]
            removed = [label for label in remote.labels if label not in draft.labels]
            args = [arg for label in added for arg in ("--add-label", label)] + [arg for label in removed for arg in ("--remove-label", label)]
            if args:
                changes.append(Change(UPDATE, draft, f"labels   #{number}  {signed(added, removed)}", lambda args=args: gh("issue", "edit", str(number), "--repo", self.repo, *args), (number,)))

        # The assignees.
        if draft.assignees is not None:
            assignees = [self.login(name) for name in draft.assignees]
            added = [name for name in assignees if name not in remote.assignees]
            removed = [name for name in remote.assignees if name not in assignees]
            args = [arg for name in added for arg in ("--add-assignee", name)] + [arg for name in removed for arg in ("--remove-assignee", name)]
            if args:
                changes.append(Change(UPDATE, draft, f"assign   #{number}  {signed(added, removed)}", lambda args=args: gh("issue", "edit", str(number), "--repo", self.repo, *args), (number,)))

        # The parent. If the parent draft has no issue yet, `apply` moves the issue after it creates the parent.
        parent = self.tree.parent_of(draft)
        old = f"#{remote.parent}" if remote.parent else "none"
        if draft.parent_ref and parent is None:
            changes.append(Change(MOVE, draft, f"move     #{number}  {old} → new {self.tree.target(draft, draft.parent_ref).number}", lambda: None))
        elif parent and parent != remote.parent:
            changes.append(Change(MOVE, draft, f"move     #{number}  {old} → #{parent}", lambda: self.move(number, parent), tuple(n for n in (number, parent, remote.parent) if n)))

        # The board fields. A missing key leaves the field as it is.
        for field, wanted, current in ((self.board.status, draft.status, remote.status), (self.board.priority, draft.priority, remote.priority)) if self.board else ():
            if wanted is None or wanted == current:
                continue
            text = f"{field.name.lower():<8} #{number}  {current or 'none'} → {wanted or 'none'}"
            changes.append(Change(FIELDS, draft, text, lambda field=field, wanted=wanted: field.set(self.board, self.board.item(self.repo, number), wanted), (number,)))

        # The blockers. If a blocker draft has no issue yet, `apply` adds the link after it creates the blocker.
        if draft.blocked_by is not None:
            wanted, pending = self.tree.blockers_of(draft, self.repo)
            for key in wanted:
                if key not in remote.blocked_by:
                    text = f"block    #{number}  blocked by {short(key, self.repo)}"
                    changes.append(Change(BLOCK, draft, text, lambda key=key: self.block(number, key), (number, *local(key))))
            for pending_number in pending:
                changes.append(Change(BLOCK, draft, f"block    #{number}  blocked by new {pending_number}", lambda: None))
            for key in remote.blocked_by:
                if key not in wanted:
                    text = f"unblock  #{number}  no longer blocked by {short(key, self.repo)}"
                    changes.append(Change(UNBLOCK, draft, text, lambda key=key: self.unblock(number, key), (number, *local(key))))

        # Close last.
        if draft.state == "closed" and remote.state == "open":
            changes.append(Change(CLOSE, draft, f"close    #{number}", lambda: gh("issue", "close", str(number), "--repo", self.repo), nearby))
        return changes

    def with_body(self, draft, args):
        """Runs `gh <args> --body-file <file>` with the body of `draft`, and returns its output."""
        with tempfile.NamedTemporaryFile("w", suffix=".md") as body:
            body.write(self.tree.body_of(draft))
            body.flush()
            output = gh(*args, "--body-file", body.name)
        return output

    def move(self, number, parent):
        """Makes `number` a sub-issue of `parent`, and takes it from its old parent."""
        gh("api", f"repos/{self.repo}/issues/{parent}/sub_issues", "-X", "POST", "-F", f"sub_issue_id={issue_id(self.repo, number)}", "-F", "replace_parent=true")

    def block(self, number, key):
        repo, _, blocker = key.partition("#")
        gh("api", f"repos/{self.repo}/issues/{number}/dependencies/blocked_by", "-X", "POST", "-F", f"issue_id={issue_id(repo, int(blocker))}")

    def unblock(self, number, key):
        repo, _, blocker = key.partition("#")
        gh("api", f"repos/{self.repo}/issues/{number}/dependencies/blocked_by/{issue_id(repo, int(blocker))}", "-X", "DELETE")

    def login(self, name):
        """The GitHub login of an assignee. `@me` is the user of `gh`."""
        if name != "@me":
            return name
        if self.me is None:
            self.me = gh("api", "user", "--jq", ".login")
        return self.me

    def refresh(self, numbers):
        """Writes the current `updatedAt` of each issue into its draft. An issue without draft needs nothing."""
        drafts = {draft.issue: draft for draft in self.tree.walk() if draft.issue}
        owner, name = self.repo.split("/")
        query = "query($owner: String!, $name: String!, $number: Int!) { repository(owner: $owner, name: $name) { issue(number: $number) { updatedAt } } }"
        for number in numbers:
            if number not in drafts:
                continue
            updated = graphql(query, owner=owner, name=name, number=number)["repository"]["issue"]["updatedAt"]
            drafts[number].set_meta("updated", updated)


def short(key, repo):
    """`#n` for an issue of `repo`, `owner/repo#n` for the others."""
    other, _, number = key.partition("#")
    name = f"#{number}" if other == repo else key
    return name


def export(repo, number, out, board):
    """Writes the open sub-issues of `number` as drafts below `out`, and returns the top folder."""

    def write_level(parent, folder, parent_ref):
        """Writes the open sub-issues of `parent` into `folder`, and their sub-issues below it."""
        if not parent.children:
            return
        os.makedirs(folder)
        for index, child in enumerate(parent.children, start=1):
            # Write the draft. Every list item is a JSON string, so a comma in a label survives.
            remote = Remote.fetch(repo, child, board)
            name = f"{index:02d}-{slug(remote.title)}"
            meta = [
                "---",
                f"title: {json.dumps(remote.title, ensure_ascii=False)}",
                f"labels: [{', '.join(json.dumps(label, ensure_ascii=False) for label in remote.labels)}]",
                f'parent: "{parent_ref}"',
                f"status: {remote.status}",
                f"priority: {remote.priority}",
                f"assignees: [{', '.join(json.dumps(login) for login in remote.assignees)}]",
                f"blocked_by: [{', '.join(json.dumps(short(key, repo)) for key in remote.blocked_by)}]",
                "state: open",
                f"updated: {remote.updated}",
                f"issue: https://github.com/{repo}/issues/{child}",
                "---",
            ]
            with open(os.path.join(folder, name + ".md"), "w", encoding="utf-8") as out_file:
                out_file.write("\n".join(meta) + "\n\n" + remote.body + "\n")

            # Write its sub-issues.
            write_level(remote, os.path.join(folder, name + ".sub"), f"../{name}.md")

    # Refuse to overwrite an earlier export.
    top = Remote.fetch(repo, number, board)
    folder = os.path.join(out, f"{number}-{slug(top.title)}.sub")
    if os.path.exists(folder):
        sys.exit(f"{folder} exists already. Move it away first.")
    if not top.children:
        sys.exit(f"#{number} has no open sub-issues")

    write_level(top, folder, f"#{number}")
    return folder


def main():

    def print_tree(drafts, depth=0):
        for draft in drafts:
            state = f"#{draft.issue}" if draft.issue else "new"
            closed = "  closed" if draft.state == "closed" else ""
            status = f"  {draft.status}" if draft.status else ""
            priority = f"  {draft.priority}" if draft.priority else ""
            assignees = f"  {' '.join(draft.assignees)}" if draft.assignees else ""
            print(f"{'  ' * depth}{draft.number}  {draft.title}  [{', '.join(draft.labels or [])}]{status}{priority}{assignees}{closed}  {state}")
            print_tree(draft.children, depth + 1)

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["check", "plan", "apply", "export"])
    parser.add_argument("target", help="the folder with the drafts of the first level, or for `export` the issue number")
    parser.add_argument("out", nargs="?", help="for `export`: the folder to write the drafts into")
    parser.add_argument("--repo", required=True, help="owner/repo")
    parser.add_argument("--project", help="the board as <owner>/<number>, if the parent issue is on none or on several")
    args = parser.parse_args()

    # Export writes drafts and needs no tree.
    if args.command == "export":
        number = int(args.target.lstrip("#"))
        board = Board.named(args.project) if args.project else Board.of_issue(args.repo, number)
        folder = export(args.repo, number, args.out or ".", board)
        print(folder)
        return

    # Check the tree.
    tree = Tree(args.target)
    board = Board.named(args.project) if args.project else Board.of_issue(args.repo, tree.parent) if tree.parent else None
    problems = check(tree, args.repo, board)
    if problems:
        print("\n".join(problems), file=sys.stderr)
        sys.exit(1)
    if args.command == "check":
        if board:
            print(f"board: {board.title}")
        print_tree(tree.drafts)
        return

    # Plan, or apply.
    sync = Sync(tree, args.repo, board)
    if args.command == "plan":
        changes, conflicts = sync.plan()
        for change in changes:
            print(change.text)
        for conflict in conflicts:
            print(f"conflict {conflict}")
        if not changes and not conflicts:
            print("no changes")
        sys.exit(1 if conflicts else 0)

    sync.apply()
    print()
    print_tree(tree.drafts)


if __name__ == "__main__":
    main()
