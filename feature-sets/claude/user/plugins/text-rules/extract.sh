#!/usr/bin/env python3
"""Print the text of each Edit and Write call after the last typed user message.

Usage: extract.sh <transcript.jsonl>
"""

import json
import sys


def is_typed_user_message(entry):
    if entry.get("type") != "user" or entry.get("isMeta"):
        return False

    # A tool result also has the type "user". Only text content comes from the user.
    content = entry.get("message", {}).get("content")
    if isinstance(content, str):
        return True

    return any(part.get("type") == "text" for part in content or [])


def main():
    # Claude Code can still be writing the last line, so skip lines that do not parse.
    entries = []
    with open(sys.argv[1]) as transcript:
        for line in transcript:
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError:
                pass

    # Keep only the entries of this turn.
    starts = [i for i, entry in enumerate(entries) if is_typed_user_message(entry)]
    turn = entries[starts[-1] + 1 :] if starts else entries

    # Print the new text of each Edit and Write call.
    for entry in turn:
        if entry.get("type") != "assistant":
            continue

        for part in entry["message"].get("content", []):
            if part.get("type") != "tool_use" or part.get("name") not in ("Edit", "Write"):
                continue

            tool_input = part["input"]
            text = tool_input.get("new_string", tool_input.get("content", ""))
            print(f"== {part['name']} {tool_input.get('file_path')}\n{text}\n")


main()
