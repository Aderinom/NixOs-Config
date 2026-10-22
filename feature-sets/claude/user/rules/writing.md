# Writing rules

## Language

Write in Simplified Technical English.

Hard rules:

- 20 words per sentence at most for instructions. 25 for descriptions.
- One idea per sentence. A cause and its effect count as one idea. Join them
  with "so" or "because".
- Active voice only.
- Present tense. Do not write "is doing" when "does" works.
- One meaning per word. Do not swap in near-synonyms.
- Put the condition first ("If X, then do Y").
- No hedging. Drop should, would, may, and might when you can state the fact.
- Use the shortest common word that works. If you would not say a word out
  loud to a colleague, swap it for the plain one.
- Plain words, full detail. Simple words do not mean less information.
- Keep real technical terms. A bind mount stays a bind mount. Explain a term
  once, right after you first use it.
- Leave code, commands, paths, and error messages byte-exact. Do not style
  them.
- No em-dashes.

These rules cover everything you write: chat, docs, and code comments.

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
- Lead-ins that announce the next line: "This has some effects to know:",
  "Two variables need care:", "The next section explains them." Start with
  the content.

## Comments and documentation

- Keep docs short. Write the shortest form I can act on.
- Docs must show what exists and what is possible.
- Before you write, decide why the reader opens the doc. If they come to
  do a task, put the tasks first and how it works after them. If they come
  to understand the system, start with the overview and put the tasks last.
- If a reader finds a fact in the code within a minute, point at the file.
  Put only the other facts in the docs.
- Pick the topics before you write. Give each topic depth by its weight for
  the reader, not by the order in which you read the code.
- If a unit has a header comment, point the docs at it. Do not restate it.
- If I ask for detailed docs, go deeper on what the code does not show. Do
  not add more topics.
- If a reader hits the behavior without opening the file, put the reason in
  the docs.
- If only a reader who edits the code hits it, put the reason at the code.
- Do not argue for a decision in the docs.
- Write a comment only where the reader cannot work it out from the code.
  The thought comments in `code-layout.md` are the exception.
- Write each fact in one place only.
- Repeat a fact only in an overview. The overview points at the one source.
- Keep an overview at the level that carries the idea. Do not list single
  files. They move.
- Assume a lazy maintainer. Write only what that person keeps current.
- Do not write long lists of things. A list goes stale on the first change,
  unless a tool checks it or builds it.
- Name the source of truth. Do not copy what it says.
- If you write or edit a Markdown table, align its columns: pad each cell
  to the column width, as Prettier does. If the file has other tables that
  are not aligned, align them too.
- Comment an if-check in two parts. Say what the code tests. Then say what
  changes because of it.
- If the branch below already shows the result, drop the second part.
- Use the same words the code uses. Do not reword a test into some other idea.
- Mark open work in the code with a `TODO:` comment, the way a person does:
  `// TODO:` in Rust, Go, or C, and the comment syntax of the language in
  others.
- If the work spans several sessions or many units, also keep a `TODO.md`
  that a person can read. It holds what has no single place in the code:
  the order of the work, open decisions, and tasks across units. It does not
  repeat the `TODO:` comments.
- If the project already has a place for open work, such as an issue
  tracker, use that and do not add a `TODO.md`.
