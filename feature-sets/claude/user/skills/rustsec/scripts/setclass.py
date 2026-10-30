#!/usr/bin/env python3
"""Sets the Class of rows in the `## Advisories` table and aligns the table.

    setclass.py <document> <class> <advisory> <crate> <version> [<advisory> <crate> <version>]...
    setclass.py <document> --align

The arguments after <class> come in triples, and `*` matches any value. The
script prints how many rows each triple changed.

With `--align`, the script only aligns the table.
"""

import sys

COLUMNS = 8


def split_row(line):
    """Returns the trimmed cells of a table row."""
    return [cell.strip() for cell in line.strip()[1:-1].split("|")]


def render(rows):
    """Renders the rows as a table with aligned columns, the second row as the separator."""
    widths = [max(len(row[i]) for n, row in enumerate(rows) if n != 1) for i in range(COLUMNS)]
    out = []
    for n, row in enumerate(rows):
        cells = ["-" * w if n == 1 else c.ljust(w) for c, w in zip(row, widths)]
        out.append("| " + " | ".join(cells) + " |")
    return out


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    path, new_class, *specs = sys.argv[1:]

    # Find the advisories table: it starts at its header and ends at the first non-table line.
    lines = open(path, encoding="utf-8").read().split("\n")
    start = next(i for i, line in enumerate(lines) if line.startswith("| Advisory"))
    end = next((i for i in range(start, len(lines)) if not lines[i].startswith("|")), len(lines))
    rows = [split_row(line) for line in lines[start:end]]

    # Set the class of each row that matches a triple.
    if new_class != "--align":
        if len(specs) % 3:
            sys.exit("the arguments after <class> must come in triples: advisory crate version")
        for i in range(0, len(specs), 3):
            want = specs[i:i + 3]
            hits = 0
            for row in rows[2:]:
                if all(w in ("*", have) for w, have in zip(want, (row[0], row[2], row[3]))):
                    row[7] = new_class
                    hits += 1
            print(f"{' '.join(want)}: {hits} rows -> {new_class}")

    lines[start:end] = render(rows)
    open(path, "w", encoding="utf-8").write("\n".join(lines))


if __name__ == "__main__":
    main()
