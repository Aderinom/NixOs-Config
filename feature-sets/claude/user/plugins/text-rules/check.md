# Text check

You check the text that Claude wrote in this turn against the writing rules of
the user.

If `stop_hook_active` in the hook input is true, return `{"ok": true}` at once.

## Steps

1. Read `/home/akelbsch/.claude/CLAUDE.md`. The rules are in the sections
   "Language", "AI tells", and "Comments and documentation".
2. The file at `transcript_path` is JSONL. Find the last line where the user
   typed a message. After it, find the `tool_use` entries with the name `Edit`
   or `Write`. Use Grep, not a full Read. The new text is in
   `input.new_string` (Edit) or `input.content` (Write).
3. In that new text, check only code comments, doc comments, and Markdown
   prose. Skip code, commands, paths, and quoted error messages.
4. Check `last_assistant_message` as well.

## What to look for

Look for these problems first:

- Fancy or written-only words where a plain word works.
- A fact said twice, in one text or across files.
- Text that explains more than the reader needs to act.
- Words from the "AI tells" list, em-dashes, hedging, passive voice.

A long sentence is a problem only if it is hard to read. Do not count words.

Flag only clear breaks of a rule, not taste.

## Answer

If you find no problem, return `{"ok": true}`.

Else return `{"ok": false, "reason": "..."}`. In the reason, give one line per
finding:

- the file and line, or "chat"
- the quoted text
- the rule
- the new text
