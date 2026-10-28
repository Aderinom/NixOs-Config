#!/usr/bin/env python3
"""Sorts the survivors of a Stryker run, so only the real candidates are left.

Usage:

    stryker-survivors.py <report.json> [--text <regex>]...

<report.json> is the output of the Stryker `json` reporter. The script reads
every mutant that survived or that no test covers. It counts a mutant as
text when its source line matches a text pattern. The patterns are a
`console.` call, an `Error` that the code builds, and each `--text` regex,
such as the call of a project logger. A line also counts when the call
starts on the line before, as in a log call over several lines.

It prints the score of each file, the number of text survivors, and each
other survivor with its place, its mutator, its line, and its replacement.
Sort those by hand into equivalent mutants and gaps.
"""

import argparse
import json
import re

TEXT_PATTERNS = [r'\bconsole\.\w+\(', r'\bnew \w*Error\(']


def main() -> None:
    parser = argparse.ArgumentParser(usage=__doc__)
    parser.add_argument('report')
    parser.add_argument('--text', action='append', default=[])
    args = parser.parse_args()
    text = re.compile('|'.join(TEXT_PATTERNS + args.text))

    # Collect the survivors, and split off the text ones.
    report = json.load(open(args.report))
    scores = []
    text_count = 0
    candidates = []
    for path, file in sorted(report['files'].items()):
        lines = file['source'].split('\n')
        statuses = [mutant['status'] for mutant in file['mutants']]
        detected = statuses.count('Killed') + statuses.count('Timeout')
        scores.append((path, detected, len(statuses)))
        for mutant in file['mutants']:
            if mutant['status'] not in ('Survived', 'NoCoverage'):
                continue
            number = mutant['location']['start']['line']
            line = lines[number - 1].strip()
            before = lines[number - 2].strip() if number > 1 else ''
            opens_call = before.endswith('(') and text.search(before)
            if text.search(line) or opens_call:
                text_count += 1
                continue
            candidates.append((path, number, mutant, line))

    # Print the scores, then the candidates.
    for path, detected, total in scores:
        print(f'{100 * detected / total:6.2f} %  {detected:4}/{total:<4}  {path}')
    print(f'\ntext survivors: {text_count}, other survivors: {len(candidates)}\n')
    for path, number, mutant, line in candidates:
        replacement = mutant.get('replacement', '').replace('\n', ' ')[:60]
        print(f'{path}:{number} [{mutant["mutatorName"]}] {mutant["status"]}')
        print(f'    {line[:100]}')
        print(f'    => {replacement}')


if __name__ == '__main__':
    main()
