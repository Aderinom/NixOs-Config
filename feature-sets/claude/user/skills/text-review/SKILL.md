---
name: text-review
description: Find AI-sounding text in prose, docs, or code comments and fix it in place into plain human speech. Use when the user asks to review, clean up, simplify, or "de-AI" a document, README, comment, commit message, or PR text.
---

# Plain review

Find text that sounds like an AI wrote it. Rewrite it the way a colleague
talks. Keep every fact.

The rules below copy `~/.claude/CLAUDE.md` sections "Language", "AI tells",
and "Comments and documentation". If you change one copy, change the other.

## Scope

- Change prose only: docs, comments, commit messages, PR text, chat drafts.
- Leave code, commands, paths, identifiers, and error messages byte-exact.
- If the user gives a file or diff, change only the prose in it.

## Language rules

Simplified Technical English:

- 20 words per sentence at most for instructions. 25 for descriptions.
- One idea per sentence.
- Active voice only.
- Present tense. Do not write "is doing" when "does" works.
- One meaning per word. Do not swap in near-synonyms.
- Put the condition first ("If X, then do Y").
- No hedging. Drop should, would, may, and might when you can state the fact.
- Use the shortest common word that works. If you would not say a word out
  loud to a colleague, swap it for the plain one.
- Plain words, full detail. Simple words do not mean less information.
- Keep real technical terms. Explain a term once, right after its first use.
- No em-dashes.

## Docs and comments rules

- Keep docs short. Write the shortest form the reader can act on.
- Docs show what exists and what is possible.
- If a reader hits the behavior without opening the file, put the reason in
  the docs. If only an editor of the code hits it, put the reason at the code.
- Do not argue for a decision in the docs.
- Write a comment only where the reader cannot work it out from the code.
- Write each fact in one place only. An overview points at the one source.
- Keep an overview at the level that carries the idea. Do not list single
  files.
- Do not write long lists unless a tool checks or builds them.
- Name the source of truth. Do not copy what it says.
- Comment an if-check in two parts: what the code tests, then what changes.
  If the branch below shows the result, drop the second part.
- Use the same words the code uses.

## AI tells

Cut or replace these on sight:

- Inflated words: leverage, utilize, facilitate, robust, seamless,
  comprehensive, crucial, delve, streamline, empower, ensure, various.
  Use: use, help, solid, smooth, full, key, look at, simplify, let, make sure,
  or drop the word.
- Filler openers: "It's worth noting", "Note that", "Importantly",
  "In order to", "This allows you to", "is responsible for".
- Summary closers: "In summary", "Overall", a last sentence that repeats the
  paragraph.
- Sales tone: "powerful", "elegant", "best-in-class", "out of the box".
- Pattern tricks: "not just X, but Y", three adjectives in a row, a rhetorical
  question as a heading.
- Formatting noise: bold on every other phrase, emoji in headings, a heading
  over one sentence, a bullet list where one sentence works.
- Narration in comments: "Here we", "Now we", "This function will", a comment
  that restates the next line.

## Output

Fix every finding in place. Do not ask first.

If the text already follows the rules, say so in one sentence.
