#!/usr/bin/env python3
"""Tests the parts of issues.py that need no network.

    python3 tests/offline.py

The tests replace the calls to GitHub with fakes.
"""

import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import issues  # noqa: E402

PROJECT = {"id": "BOARD", "title": "Test", "number": 1, "status": None, "priority": None}
REPO = "o/r"
SECTIONS = "## Goal\n\nG.\n\n## Scope\n\n- [ ] S.\n\n## Definition of done\n\n- [ ] D.\n"


def remote(number, **fields):
    """A fake `Remote` of an open issue without labels, assignees, parent, or blockers."""
    values = dict(
        number=number, title=f"x: issue {number}", body="Body.", state="open", updated="T0",
        labels=[], assignees=[], parent=None, blocked_by=[], status="", priority="", children=[],
    )
    values.update(fields)
    return issues.Remote(**values)


class Folder(unittest.TestCase):
    """A test with a temporary folder of drafts."""

    def setUp(self):
        self.folder = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.folder)

    def write(self, relative, front, body=SECTIONS):
        path = os.path.join(self.folder, relative)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8", newline="") as out:
            out.write(f"---\n{front}\n---\n\n{body}")
        return path


class Parse(unittest.TestCase):
    """Read the front matter."""

    def parse(self, front):
        meta, _, unread = issues.parse(f"---\n{front}\n---\n\nBody.")
        return meta, unread

    def test_quoted_list_items_hold_commas_and_brackets(self):
        meta, _ = self.parse('labels: ["a, b", c, "[WIP]", "say \\"hi\\""]')
        self.assertEqual(meta["labels"], ["a, b", "c", "[WIP]", 'say "hi"'])

    def test_bare_brackets_inside_a_list(self):
        meta, _ = self.parse("blocked_by: [[WIP], #5]")
        self.assertEqual(meta["blocked_by"], ["[WIP]", "#5"])

    def test_empty_list_and_empty_value(self):
        meta, unread = self.parse("labels: []\nassignees:\npriority:")
        self.assertEqual((meta["labels"], meta["assignees"], meta["priority"], unread), ([], [], "", []))

    def test_block_list_and_unknown_key_stay_unread(self):
        meta, unread = self.parse("assignees: alice\nlabels:\n  - a\nmilestone: 3")
        self.assertEqual(unread, ["assignees: alice", "  - a", "milestone: 3"])
        self.assertEqual(meta["labels"], [])

    def test_quoted_title(self):
        meta, _ = self.parse('title: "x: a \\"quoted\\": title"')
        self.assertEqual(meta["title"], 'x: a "quoted": title')


class Drafts(Folder):
    """Missing keys, written keys, and references."""

    def setUp(self):
        super().setUp()
        self.write("12-top.sub/01-alpha.md", 'title: "x: alpha"\nissue: https://github.com/o/r/issues/30', "Alpha.\r\nSecond line.\r\n")
        self.write("12-top.sub/01-alpha.sub/01-child.md", "title: x: child\nparent: ../01-alpha.md\nissue:", "Child of #ref:../01-alpha.md and #ref:../02-beta.md.")
        self.write("12-top.sub/02-beta.md", 'title: x: beta\nblocked_by: ["01-alpha.md", "#5", "a/b#6", "01-alpha.sub/01-child.md"]\nissue:', "Beta.")
        self.tree = issues.Tree(os.path.join(self.folder, "12-top.sub"))

    def test_missing_keys_are_none(self):
        alpha = self.tree.drafts[0]
        self.assertEqual((alpha.labels, alpha.assignees, alpha.blocked_by, alpha.state, alpha.status), (None,) * 5)

    def test_body_line_ends(self):
        self.assertEqual(issues.normalize(self.tree.drafts[0].body), "Alpha.\nSecond line.")

    def test_parent_of(self):
        alpha, child, _ = self.tree.walk()
        self.assertEqual((self.tree.parent_of(alpha), self.tree.parent_of(child)), (12, 30))

    def test_refs_resolve_only_with_issue(self):
        child = self.tree.drafts[0].children[0]
        self.assertEqual(self.tree.body_of(child), "Child of #30 and #ref:../02-beta.md.")

    def test_blockers(self):
        beta = self.tree.drafts[1]
        self.assertEqual(self.tree.blockers_of(beta, REPO), (["o/r#30", "o/r#5", "a/b#6"], ["01.01"]))

    def test_set_meta_replaces_and_adds(self):
        beta = self.tree.drafts[1]
        beta.set_meta("issue", "https://github.com/o/r/issues/31")
        beta.set_meta("updated", "2026-01-01T00:00:00Z")
        again = issues.Draft(beta.path, "02", None)
        self.assertEqual((again.issue, again.updated, again.body), (31, "2026-01-01T00:00:00Z", "Beta."))


class Compare(Folder):
    """The changes that `plan` finds, with a fake GitHub."""

    def tree(self):
        return issues.Tree(os.path.join(self.folder, "12-top.sub"))

    def plan(self, remotes, board=None):
        sync = issues.Sync(self.tree(), REPO, board)
        with mock.patch.object(issues.Remote, "fetch", side_effect=lambda repo, number, board: remotes[number]):
            changes, conflicts = sync.plan()
        return [change.text.split()[:2] for change in changes], conflicts

    def test_missing_keys_change_nothing(self):
        self.write("12-top.sub/01-a.md", 'title: "x: issue 30"\nparent: "#12"\nissue: https://github.com/o/r/issues/30', "Body.")
        changes, _ = self.plan({30: remote(30, parent=12, state="closed", labels=["l"], assignees=["alice"], blocked_by=["o/r#5"])})
        self.assertEqual(changes, [])

    def test_lists_and_state_change(self):
        front = 'title: "x: issue 30"\nparent: "#12"\nlabels: [new]\nassignees: []\nblocked_by: ["#6"]\nstate: closed\nissue: https://github.com/o/r/issues/30'
        self.write("12-top.sub/01-a.md", front, "Body.")
        changes, _ = self.plan({30: remote(30, parent=12, labels=["old"], assignees=["alice"], blocked_by=["o/r#5"])})
        self.assertEqual(changes, [["unblock", "#30"], ["labels", "#30"], ["assign", "#30"], ["block", "#30"], ["close", "#30"]])

    def test_move_and_block_on_new_drafts_show_in_plan(self):
        self.write("12-top.sub/01-new.md", "title: x: new\nstatus: Todo\nissue:")
        self.write("12-top.sub/01-new.sub/01-old.md", 'title: "x: issue 30"\nparent: ../01-new.md\nblocked_by: [../01-new.md]\nissue: https://github.com/o/r/issues/30', "Body.")
        changes, _ = self.plan({30: remote(30, parent=12)})
        self.assertEqual(changes, [["create", "01"], ["move", "#30"], ["block", "#30"]])

    def test_children_close_before_parents(self):
        self.write("12-top.sub/01-p.md", 'title: "x: issue 30"\nstate: closed\nissue: https://github.com/o/r/issues/30', "Body.")
        self.write("12-top.sub/01-p.sub/01-c.md", 'title: "x: issue 31"\nstate: closed\nissue: https://github.com/o/r/issues/31', "Body.")
        changes, _ = self.plan({30: remote(30, parent=12), 31: remote(31, parent=30)})
        self.assertEqual(changes, [["close", "#31"], ["close", "#30"]])

    def test_conflict_only_with_updated(self):
        self.write("12-top.sub/01-a.md", 'title: "x: issue 30"\nupdated: T0\nissue: https://github.com/o/r/issues/30', "Body.")
        self.write("12-top.sub/02-b.md", 'title: "x: issue 31"\nissue: https://github.com/o/r/issues/31', "Body.")
        _, conflicts = self.plan({30: remote(30, parent=12, updated="T1"), 31: remote(31, parent=12, updated="T1")})
        self.assertEqual(len(conflicts), 1)
        self.assertIn("#30", conflicts[0])

    def test_board_field_none_keeps_and_empty_clears(self):
        board = issues.Board({**PROJECT, "status": {"id": "S", "options": [{"id": "1", "name": "Todo"}]}, "priority": {"id": "P", "options": [{"id": "2", "name": "high"}]}})
        self.write("12-top.sub/01-a.md", 'title: "x: issue 30"\npriority:\nissue: https://github.com/o/r/issues/30', "Body.")
        changes, _ = self.plan({30: remote(30, parent=12, status="Todo", priority="high")}, board)
        self.assertEqual(changes, [["priority", "#30"]])


class Check(Folder):
    """`check` refuses drafts that would edit the wrong issue or lose data."""

    def problems(self):
        tree = issues.Tree(os.path.join(self.folder, "12-top.sub"))

        def gh(*args):
            fake = "[]" if args[0] == "label" else ""
            return fake

        with mock.patch.object(issues, "gh", side_effect=gh):
            problems = issues.check(tree, REPO, None)
        return "\n".join(problems)

    def front(self, issue):
        return f'title: "x: {issue[-2:]}"\nlabels: []\nparent: "#12"\nstatus:\nissue: {issue}'

    def test_issue_of_another_repository(self):
        self.write("12-top.sub/01-a.md", self.front("https://github.com/o/other/issues/30"), "Body.")
        self.assertIn("is in o/other, not in o/r", self.problems())

    def test_bad_issue_url(self):
        self.write("12-top.sub/01-a.md", self.front("#30"), "Body.")
        self.assertIn("is not `https://github.com/<owner>/<repo>/issues/<n>`", self.problems())

    def test_two_drafts_with_one_issue(self):
        self.write("12-top.sub/01-a.md", self.front("https://github.com/o/r/issues/30"), "Body.")
        self.write("12-top.sub/02-b.md", self.front("https://github.com/o/r/issues/30").replace("x: 30", "x: other"), "Body.")
        self.assertIn("the same issue as", self.problems())

    def test_empty_body_of_an_existing_issue(self):
        self.write("12-top.sub/01-a.md", self.front("https://github.com/o/r/issues/30"), "")
        self.assertIn("an empty body would erase", self.problems())

    def test_unread_line(self):
        self.write("12-top.sub/01-a.md", self.front("https://github.com/o/r/issues/30") + "\nassignees: alice", "Body.")
        self.assertIn("cannot read `assignees: alice`", self.problems())


class BoardRace(unittest.TestCase):
    """The board adds an issue on its own while `apply` adds it too."""

    def test_existing_item_after_content_already_exists(self):
        board = issues.Board(PROJECT)
        refused = subprocess.CompletedProcess([], 1, "", "gh: Content already exists in this project")
        items = {"repository": {"issue": {"projectItems": {"nodes": [
            {"id": "OTHER", "project": {"id": "ELSEWHERE"}},
            {"id": "ITEM", "project": {"id": "BOARD"}},
        ]}}}}
        with mock.patch.object(issues, "gh", return_value="NODE"), \
                mock.patch.object(issues.subprocess, "run", return_value=refused), \
                mock.patch.object(issues, "graphql", return_value=items):
            item = board.item(REPO, 7)
        self.assertEqual(item, "ITEM")

    def test_other_errors_stop_the_run(self):
        board = issues.Board(PROJECT)
        failed = subprocess.CompletedProcess([], 1, "", "gh: Something else")
        with mock.patch.object(issues, "gh", return_value="NODE"), \
                mock.patch.object(issues.subprocess, "run", return_value=failed):
            with self.assertRaises(SystemExit):
                board.item(REPO, 7)


class Helpers(unittest.TestCase):

    def test_slug(self):
        self.assertEqual(issues.slug("endhost/web: 02.01 Add a WAP, now!"), "add-a-wap-now")

    def test_slug_length(self):
        self.assertLessEqual(len(issues.slug("c: " + "word " * 30)), 60)

    def test_short(self):
        self.assertEqual((issues.short("o/r#5", REPO), issues.short("a/b#6", REPO)), ("#5", "a/b#6"))


if __name__ == "__main__":
    unittest.main()
