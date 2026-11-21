#!/usr/bin/env python3
"""Tests review_md.py.

    python3 tests/review_md.py

The tests write their threads with the real `threads.py` of the `code-threads` skill, into a
temporary workspace.
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import review_md  # noqa: E402
from review_md import Comment, Markdown, Review, Threads  # noqa: E402

REVIEW = "branch-review"
SOURCE = "src/lib.rs"
SOURCE_LINES = [f"line {n}" for n in range(1, 21)]


class Workspace(unittest.TestCase):
    """A test with a temporary workspace that holds two source files and a review log."""

    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root)
        (self.root / "src").mkdir()
        (self.root / SOURCE).write_text("\n".join(SOURCE_LINES) + "\n")
        (self.root / "src/other.rs").write_text("other\n" * 20)

    def threads(self, *args, body=None, review=REVIEW):
        """Runs `threads.py` on the workspace, and returns its output."""
        command = [sys.executable, "-I", str(review_md.THREADS), "--root", str(self.root), "--review", review, *args]
        out = subprocess.run(command, input=body, capture_output=True, text=True, check=True)
        return out.stdout.strip()

    def add(self, line, body, path=SOURCE, author="agent", end=None):
        """Opens a thread on `line` of `path`, and returns its ID."""
        return self.threads("add", str(self.root / path), str(line), str(end or line), "-", "--author", author, body=body)

    def review(self, blocking=(), topics=None):
        """Builds the review, with a topic for each open thread unless `topics` is given."""
        threads = Threads.read(self.root, REVIEW)
        if topics is None:
            topics = {t["id"]: f"topic {t['id']}" for t in threads if t["status"] == "open"}
        return Review.from_threads(1, threads, self.root, set(blocking), topics)


class ReviewFromThreads(Workspace):
    def test_should_keep_only_the_open_threads(self):
        self.add(1, "🤖 kept")
        self.threads("resolve", self.add(2, "🤖 dropped"))

        review = self.review()

        self.assertEqual([c.body for c in review.comments], ["🤖 kept"])

    def test_should_use_the_last_user_comment_with_source_user_after_a_reply(self):
        thread = self.add(1, "🤖 agent text")
        self.threads("reply", thread, "-", "--author", "reviewer", body="first reply")
        self.threads("reply", thread, "-", "--author", "reviewer", body="last reply")

        [comment] = self.review().comments

        self.assertEqual((comment.body, comment.source), ("last reply", "user"))

    def test_should_use_the_first_agent_comment_with_source_ai_if_only_the_agent_wrote(self):
        thread = self.add(1, "🤖 first")
        self.threads("reply", thread, "-", body="🤖 second")

        [comment] = self.review().comments

        self.assertEqual((comment.body, comment.source), ("🤖 first", "ai"))

    def test_should_give_a_thread_that_the_user_started_the_source_user(self):
        self.add(1, "nit: mine", author="reviewer")

        [comment] = self.review().comments

        self.assertEqual((comment.body, comment.source), ("nit: mine", "user"))

    def test_should_set_blocking_for_the_listed_ids_and_discussing_for_others(self):
        blocking = self.add(1, "🤖 a")
        self.add(2, "🤖 b")

        states = {c.line: c.state for c in self.review(blocking=[blocking]).comments}

        self.assertEqual(states, {1: "blocking", 2: "discussing"})

    def test_should_put_blocking_first_then_sort_by_path_and_line_and_number_them(self):
        self.add(9, "🤖 late")
        self.add(2, "🤖 early")
        self.add(1, "🤖 other", path="src/other.rs")
        blocking = self.add(15, "🤖 blocking")

        comments = self.review(blocking=[blocking]).comments

        order = [(c.key, c.path, c.line) for c in comments]
        self.assertEqual(order, [("C1", SOURCE, 15), ("C2", SOURCE, 2), ("C3", SOURCE, 9), ("C4", "src/other.rs", 1)])

    def test_should_stop_on_an_id_that_names_no_open_thread(self):
        thread = self.add(1, "🤖 a")
        topics = {thread: "t"}
        rows = [
            ("unknown blocking", {"t_nope"}, topics),
            ("unknown topic", set(), {**topics, "t_nope": "t"}),
        ]
        for label, blocking, topics in rows:
            with self.subTest(label), self.assertRaises(SystemExit) as stop:
                self.review(blocking, topics)
            self.assertIn("t_nope", str(stop.exception.code), label)

    def test_should_stop_and_name_each_open_thread_without_a_topic(self):
        first = self.add(1, "🤖 a")
        second = self.add(2, "🤖 b")

        with self.assertRaises(SystemExit) as stop:
            self.review(topics={})

        self.assertIn(first, str(stop.exception.code))
        self.assertIn(second, str(stop.exception.code))

    def test_should_replace_a_pipe_in_a_topic(self):
        thread = self.add(1, "🤖 a")

        [comment] = self.review(topics={thread: "select | timeout"}).comments

        self.assertEqual(comment.topic, "select / timeout")

    def test_should_take_the_code_of_the_thread_lines(self):
        self.add(3, "🤖 a", end=5)

        [comment] = self.review().comments

        self.assertEqual(comment.code, "line 3\nline 4\nline 5")


class ThreadsCode(Workspace):
    def test_should_return_the_lines_from_start_to_end(self):
        self.assertEqual(Threads.code(self.root / SOURCE, 3, 5), "line 3\nline 4\nline 5")

    def test_should_return_an_empty_string_if_the_file_is_gone(self):
        self.assertEqual(Threads.code(self.root / "gone.rs", 1, 2), "")


def comment(key="C1", line=3, code="line 3", body="🤖 Text.", state="discussing", topic="a topic", source="ai"):
    """A comment on `SOURCE`."""
    return Comment(key, SOURCE, line, state, topic, source, body, code)


class ReviewToMarkdown(unittest.TestCase):
    def test_should_write_the_state_path_code_and_body_of_each_comment(self):
        text = Review(1, [comment(state="blocking")]).to_markdown()

        section = text.split("## C1. lib.rs:3: a topic\n", 1)[1]
        self.assertTrue(section.startswith("\nState: `blocking`\n\n`src/lib.rs`\n\n```rust\nline 3\n```\n\n🤖 Text.\n"))

    def test_should_leave_out_the_code_block_if_the_code_is_blank(self):
        text = Review(1, [comment(code="   ")]).to_markdown()

        self.assertNotIn("```", text)

    def test_should_write_one_link_target_per_comment_to_its_heading(self):
        text = Review(1, [comment(), comment(key="C2", line=7, topic="other topic")]).to_markdown()

        links = text.split("<!-- Links -->\n", 1)[1]
        self.assertEqual(links.strip().split("\n"), ["[C1]: #c1-librs3-a-topic", "[C2]: #c2-librs7-other-topic"])


class MarkdownTable(unittest.TestCase):
    def test_should_pad_each_column_to_its_widest_cell(self):
        lines = Markdown.table(["#", "Topic"], [["[C1]", "x"], ["[C10]", "long topic"]])

        self.assertEqual(
            lines,
            [
                "| #     | Topic      |",
                "| ----- | ---------- |",
                "| [C1]  | x          |",
                "| [C10] | long topic |",
            ],
        )


class MarkdownFence(unittest.TestCase):
    def test_should_pick_the_language_and_a_fence_longer_than_the_code(self):
        rows = [
            ("known suffix", "a.rs", "x", "```rust", "```"),
            ("unknown suffix", "a.xyz", "x", "```", "```"),
            ("backticks in code", "a.md", "```\nx\n```", "````markdown", "````"),
        ]
        for label, path, code, opening, closing in rows:
            fence = Markdown.fence(path, code)
            self.assertEqual((fence[0], fence[2]), (opening, closing), label)


class MarkdownSlug(unittest.TestCase):
    def test_should_return_the_github_anchor(self):
        rows = [
            ("lowercase", "C1. Lib.rs:3: Topic", "c1-librs3-topic"),
            ("underscore and hyphen kept", "C2. a_b-c.rs:1: x", "c2-a_b-crs1-x"),
            ("backticks removed", "C3. a.rs:1: `name` doc", "c3-ars1-name-doc"),
        ]
        for label, heading, slug in rows:
            self.assertEqual(Markdown.slug(heading), slug, label)


def markdown(*sections, table=None):
    """A REVIEW.md with `sections`, each a (key, state, line, rest) tuple on `SOURCE`."""
    rows = table or [(key, state) for key, state, *_ in sections]
    parts = ["# Review of PR #5", "", "| # | Where | Topic | Source | State |", "| - | - | - | - | - |"]
    parts += [f"| [{key}] | x | x | user | {state} |" for key, state in rows]
    for key, state, line, rest in sections:
        parts += ["", f"## {key}. lib.rs:{line}: topic {key}", "", f"State: `{state}`", "", f"`{SOURCE}`", "", rest]
    parts += ["", "<!-- Links -->", "", "[C1]: #c1"]
    return "\n".join(parts) + "\n"


class ReviewFromMarkdown(unittest.TestCase):
    def test_should_read_each_field_of_the_comment(self):
        text = markdown(("C1", "blocking", 12, "```rust\nline 12\n```\n\n🤖 Body.\n\nSecond paragraph."))

        review = Review.from_markdown(text)

        expected = Comment("C1", SOURCE, 12, "blocking", "topic C1", "user", "🤖 Body.\n\nSecond paragraph.", "line 12")
        self.assertEqual(review, Review(5, [expected]))

    def test_should_keep_a_code_block_that_is_part_of_the_body(self):
        body = "nit:\n\n```rust\n/// Doc.\n```"
        text = markdown(("C1", "discussing", 1, "```rust\nline 1\n```\n\n" + body))

        [result] = Review.from_markdown(text).comments

        self.assertEqual(result.body, body)

    def test_should_stop_and_name_each_comment_whose_state_disagrees_with_the_table(self):
        sections = [("C1", "discussing", 1, "A."), ("C2", "discussing", 2, "B.")]
        text = markdown(*sections, table=[("C1", "blocking"), ("C2", "discussing")])

        with self.assertRaises(SystemExit) as stop:
            Review.from_markdown(text)

        self.assertIn("C1", str(stop.exception.code))
        self.assertNotIn("C2", str(stop.exception.code))

    def test_should_stop_if_a_comment_has_no_row_in_the_table(self):
        text = markdown(("C1", "discussing", 1, "A."), table=[("C2", "discussing")])

        with self.assertRaises(SystemExit) as stop:
            Review.from_markdown(text)

        self.assertIn("C1", str(stop.exception.code))

    def test_should_stop_if_a_section_has_no_state_or_no_path(self):
        rows = [
            ("no state", f"## C1. lib.rs:1: t\n\n`{SOURCE}`\n\nBody.\n"),
            ("no path", "## C1. lib.rs:1: t\n\nState: `discussing`\n\nBody.\n"),
        ]
        for label, section in rows:
            text = "| [C1] | x | x | ai | discussing |\n\n" + section
            with self.subTest(label), self.assertRaises(SystemExit):
                Review.from_markdown(text)

    def test_should_stop_if_a_code_block_has_no_closing_fence(self):
        text = markdown(("C1", "discussing", 1, "```rust\nline 1\n\nBody."))

        with self.assertRaises(SystemExit):
            Review.from_markdown(text)


class ReviewToPayloads(unittest.TestCase):
    def test_should_return_the_publish_fields_of_each_comment(self):
        payloads = Review(1, [comment(state="blocking")]).to_payloads()["comments"]

        self.assertEqual(payloads, [{"key": "C1", "path": SOURCE, "line": 3, "disposition": "blocking", "body": "🤖 Text."}])

    def test_should_return_the_github_state_of_the_dispositions(self):
        rows = [
            ("one blocking", ["blocking", "discussing"], "CHANGES_REQUESTED"),
            ("only discussing", ["discussing", "discussing"], "COMMENTED"),
        ]
        for label, states, expected in rows:
            comments = [comment(key=f"C{n}", state=state) for n, state in enumerate(states, 1)]
            self.assertEqual(Review(1, comments).to_payloads()["github_state"], expected, label)


class CliPair(unittest.TestCase):
    def test_should_split_on_the_first_equals_sign(self):
        self.assertEqual(review_md.Cli.pair("t_a=x = y"), ("t_a", "x = y"))

    def test_should_stop_on_a_topic_without_an_equals_sign(self):
        with self.assertRaises(SystemExit):
            review_md.Cli.pair("t_a")


class RoundTrip(Workspace):
    """The Markdown reads back into the model that wrote it, also after the edits of the user."""

    def setUp(self):
        super().setUp()
        self.blocking = self.add(4, "🤖 Agent text.\n\nSecond paragraph.", end=6)
        self.add(10, "nit:\n\n```rust\n/// Doc.\n```", author="reviewer")
        self.built = self.review(blocking=[self.blocking])

    def test_should_read_the_markdown_back_into_the_same_review(self):
        self.assertEqual(Review.from_markdown(self.built.to_markdown()), self.built)

    def test_should_read_a_line_that_the_user_fixed_in_a_heading(self):
        text = self.built.to_markdown().replace("## C1. lib.rs:4:", "## C1. lib.rs:5:")

        self.assertEqual(Review.from_markdown(text).comments[0].line, 5)

    def test_should_read_a_state_that_the_user_changed_in_the_table_and_the_state_line(self):
        text = self.built.to_markdown()
        text = text.replace("| ai     | blocking   |", "| ai     | discussing |")
        text = text.replace("State: `blocking`", "State: `discussing`")

        review = Review.from_markdown(text)

        self.assertEqual([c.state for c in review.comments], ["discussing", "discussing"])
        self.assertEqual(review.github_state(), "COMMENTED")


class CommandLine(Workspace):
    """The commands with their defaults: the review and the file follow the git branch."""

    def setUp(self):
        super().setUp()
        subprocess.run(["git", "init", "-q", "-b", "topic", str(self.root)], check=True)

        # The default review of the branch `topic` is `topic-review`.
        self.thread = self.threads("add", str(self.root / SOURCE), "2", "-", body="🤖 Text.", review="topic-review")
        self.build = ["build", "--pr", "7", "--blocking", self.thread, "--topic", f"{self.thread}=a topic"]
        self.file = self.root / "_local/topic/REVIEW.md"

    def run_script(self, *args):
        script = Path(review_md.__file__).resolve()
        return subprocess.run([sys.executable, "-I", str(script), *args], cwd=self.root, capture_output=True, text=True)

    def test_should_build_and_parse_the_file_of_the_branch(self):
        built = self.run_script(*self.build)
        parsed = self.run_script("parse")

        self.assertEqual(built.returncode, 0, built.stderr)
        self.assertTrue(self.file.exists())
        result = json.loads(parsed.stdout)
        self.assertEqual(result["github_state"], "CHANGES_REQUESTED")
        self.assertEqual([(c["line"], c["body"]) for c in result["comments"]], [(2, "🤖 Text.")])

    def test_should_print_the_markdown_and_write_no_file_on_a_dry_run(self):
        out = self.run_script(*self.build, "--dry-run")

        self.assertEqual(out.returncode, 0, out.stderr)
        self.assertIn("# Review of PR #7", out.stdout)
        self.assertIn("## C1. lib.rs:2: a topic", out.stdout)
        self.assertFalse(self.file.exists())

    def test_should_stop_on_a_topic_without_an_equals_sign(self):
        out = self.run_script("build", "--pr", "7", "--topic", "t_a")

        self.assertNotEqual(out.returncode, 0)
        self.assertIn("--topic needs", out.stderr)


if __name__ == "__main__":
    unittest.main()
