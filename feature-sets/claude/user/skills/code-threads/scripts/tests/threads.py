#!/usr/bin/env python3
"""Tests the `list --json` command of threads.py.

    python3 tests/threads.py

The tests run threads.py on a temporary workspace.
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

THREADS = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))) / "threads.py"
REVIEW = "test-review"


class ListJson(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.root)
        (self.root / "a.rs").write_text("one\ntwo\nthree\n")

        # One thread of the agent that waits for no one, and one of the user that waits for us.
        self.ours = self.threads("add", str(self.root / "a.rs"), "1", "🤖 ours")
        self.theirs = self.threads("add", str(self.root / "a.rs"), "2", "3", "nit: theirs", "--author", "reviewer")

    def threads(self, *args):
        command = [sys.executable, "-I", str(THREADS), "--root", str(self.root), "--review", REVIEW, *args]
        return subprocess.run(command, capture_output=True, text=True, check=True).stdout.strip()

    def test_should_print_only_the_waiting_threads_without_all(self):
        threads = json.loads(self.threads("list", "--json"))

        self.assertEqual([t["id"] for t in threads], [self.theirs])

    def test_should_print_every_thread_with_all_with_the_fields_of_review_threads(self):
        threads = json.loads(self.threads("list", "--all", "--json"))

        self.assertEqual([t["id"] for t in threads], [self.ours, self.theirs])
        self.assertEqual(
            threads[1],
            {
                "id": self.theirs,
                "file": "a.rs",
                "range": {"startLine": 2, "endLine": 3},
                "status": "open",
                "waiting": True,
                "comments": [{"id": f"{self.theirs}.c1", "author": "reviewer", "body": "nit: theirs"}],
            },
        )


if __name__ == "__main__":
    unittest.main()
