#!/usr/bin/env python3
"""Proves that a Vitest test catches a change of the code.

Usage, from the package that holds `node_modules/.bin/vitest`:

    prove-vitest.py <source file> <old text> <new text> <test file> <test name pattern>

The script replaces <old text>, which must occur once, with <new text> in
<source file>. It runs the tests in <test file> whose names match <test name
pattern>, and restores <source file> in every case.

It prints CAUGHT and exits with 0 when a test fails. It prints SURVIVED and
exits with 1 when every test passes. It exits with 2 when the old text does
not occur once, or when no test matches the pattern, because then the run
proves nothing.
"""

import re
import shutil
import subprocess
import sys


def main() -> int:
    if len(sys.argv) != 6:
        print(__doc__, file=sys.stderr)
        return 2
    source, old, new, test_file, pattern = sys.argv[1:]

    # Check that the change hits exactly one place.
    text = open(source).read()
    if text.count(old) != 1:
        print(f'ERROR {source}: expected one match of {old!r}, found {text.count(old)}')
        return 2

    # Change the source, run the tests, and restore the source.
    backup = source + '.prove.bak'
    shutil.copy(source, backup)
    try:
        with open(source, 'w') as changed:
            changed.write(text.replace(old, new))
        run = subprocess.run(
            ['node_modules/.bin/vitest', 'run', test_file, '-t', pattern],
            capture_output=True,
            text=True,
        )
    finally:
        shutil.move(backup, source)

    # Read the summary line, because the failure report also says "Tests".
    output = run.stdout + run.stderr
    if re.search(r'Tests\s+.*\d+ (passed|failed)', output) is None:
        print(f'ERROR no test in {test_file} matches {pattern!r}')
        return 2
    caught = re.search(r'Tests\s+\d+ failed', output) is not None

    verdict = 'CAUGHT' if caught else 'SURVIVED'
    print(f'{verdict} {source}: {old.strip()[:60]!r}')
    return 0 if caught else 1


if __name__ == '__main__':
    sys.exit(main())
