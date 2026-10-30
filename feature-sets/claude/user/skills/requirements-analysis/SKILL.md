---
name: requirements-analysis
description: Analyze the requirements of a design before any mechanism is chosen. Collect the facts, draw the entities, their operators, and the trust between them in draw.io, fix the terms in a glossary, and write the requirements as testable MUST, MUST NOT, and MAY rules. Use when the user asks to analyze requirements, to work out a trust or deployment model, or to prepare a design section before a decision.
---

# Requirements analysis

The analysis states what must hold. It does not say how.

Keep options, mechanisms, and flows out of it until the user agrees on the
rules.

## 1. Collect the facts

- Read the issue, the sections of the design doc, the docs in the
  repository, and the code.
- If you cannot read a source, for example a Google Doc, ask the user to
  paste the section. Do not guess its content.
- Note the source of each fact: the doc, the code, or the user. A fact
  that only the user states stays unconfirmed until a doc or a person
  confirms it.
- If the sources disagree, for example on a header name, list the
  disagreement as an open question.

## 2. Draw the entities

Draw one draw.io diagram at `_local/<branch>/entities.drawio`:

- Each operator is a container (`swimlane` style), and its entities sit
  inside it. A box in a box shows ownership, so the diagram needs no
  ownership lines.
- An entity that no operator runs, for example a browser user, stays
  outside all containers.
- A solid arrow is a connection that carries traffic. Its label names what
  crosses it, for example `CONNECT + Forwarded`.
- A dashed arrow is trust. Its label names the basis, for example
  `trusts (contract)`.
- If an operator, an entity, or a relation is unconfirmed, add *(open)* to
  its label.
- If an entity holds or sees something that matters for a threat, add it
  to the label of its box, for example `sees: client IP, SNI`.
- Add a legend box for the four conventions above.
- Pin each arrow to a side of its boxes with `exitX`/`exitY` and
  `entryX`/`entryY`. Route the trust arrows around the containers with
  waypoints. Without these, the automatic routing cuts through other boxes.

If the diagram has more than about ten boxes, split it into one diagram for
the traffic and one for the trust.

### Export and check

draw.io needs a display. Xvfb gives it one.

If `ELECTRON_RUN_AS_NODE` is set, draw.io fails. The VS Code server sets
this variable, so unset it for each call.

```bash
Xvfb :99 -screen 0 1600x1200x24 >/dev/null 2>&1 & XPID=$!
export DISPLAY=:99
env -u ELECTRON_RUN_AS_NODE drawio --no-sandbox --disable-gpu \
  -x -f svg -e -o entities.drawio.svg entities.drawio
env -u ELECTRON_RUN_AS_NODE drawio --no-sandbox --disable-gpu \
  -x -f png -s 2 -o <scratchpad>/entities.png entities.drawio
kill $XPID
```

- The `-e` flag embeds the diagram in the SVG. The SVG then goes into a
  Google Doc and still opens in draw.io.
- Read the PNG and look for arrows that cross boxes and for labels that
  overlap. Fix them and export again.
- Tell the user to fix the fine layout in the draw.io app.

## 3. Write the trust relations

- Write one line for each pair of operators: who trusts whom, and through
  what, for example a contract.
- Write "no trust" where none exists. These pairs give the hardest rules.

## 4. Fix the terms

- Write a glossary. Take the terms of the existing design doc where they
  exist.
- Use each term with one meaning only, in the rules and in the chat.

## 5. Write the rules

- Group the rules by topic, for example "Uplink authentication" or
  "Client address".
- Number the rules in each group.
- Write each rule as one testable statement with MUST, MUST NOT, or MAY.
- Find the threats for each entity: what can it do if it lies, or if
  someone steals its secrets? Turn each threat into a rule. Do not list
  the threats in the output.
- Mark each rule that rests on an unconfirmed fact with *(open)*.
- Keep each rule neutral. If a rule only holds for one mechanism, for
  example "per Connection" when the check can also happen per Uplink,
  rewrite it so that both stay possible, or mark the choice as *(open)*.
- Do not add a flow. A flow depends on the mechanism.

## 6. List the open questions

- Write one table: | Topic | Question |.
- Keep only questions whose answer changes a rule or an entity.

## 7. Hand it over

- Write the analysis to `_local/<branch>/requirements.md`, in the order
  glossary, entities, trust relations, rules, open questions. The entities
  section points to the diagram.
- Show the user the rules that carry the most weight, and stop.
- After the user agrees on the rules, the next steps follow in this order:
  choose the mechanism, write the flow, then specify the API. Each is a
  separate step with its own review.
