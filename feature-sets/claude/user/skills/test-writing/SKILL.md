---
name: test-writing
description: Plan and write the tests of a unit. Lists the cases first, grouped by function and by mechanism, and agrees on the list before any test exists. Use when the user asks to write, add, port, or plan tests, or asks which cases a unit needs.
---

# Test writing

Decide which cases must exist before you write a test.

## Scale

- One new case in an existing test file: write the test (step 3), verify
  (step 4), and break the line it guards to see it fail (as in step 7).
- A few cases in one unit: steps 1 to 4, then steps 5 to 8 for that unit
  only.
- A new unit, or the tests of a whole folder: every step.

## 1. List the cases

For each unit, read its code and its doc comments. Look for these kinds of
cases:

- The normal result of each function.
- Each branch a caller can reach, and each error it can throw.
- Edge inputs: empty, missing, duplicate, out of order.
- Time: timers, retries, and expiry.
- Order and overlap: a call that starts before another one ends.
- Lifecycle: calls before start and after close or dispose.
- Each guarantee in a doc comment that another unit relies on.

Write each case as one sentence that starts with "should", for example
"should keep the newer answer when a lookup of an older round ends later".

## 2. Group the cases

Split the cases of a unit into two parts:

1. Functions. A case that one call decides goes under that function: the
   input goes in, and the result or the error comes out.
2. Mechanisms. A case that time, a sequence of calls, or an internal part
   decides goes under the mechanism it checks, for example "overlapping
   rounds", "re-auth timer", or "token retry". Name the group after the
   mechanism, so a maintainer who changes it finds its tests.

Write the list as a nested checklist: unit, then the group, then the case.
Mark a case that a test already covers with `[x]`. Mark a group or a unit
only when a test covers each of its cases.

Show me the list. Wait for my approval before you write a test.

## 3. Write the tests

- Build the groups from step 2 with the means of the language: a nested
  `describe` in TypeScript, a nested `mod` inside `mod tests` in Rust.
- The test name is the case sentence: `it('should ...')` in TypeScript,
  `fn should_...()` in Rust.
- A test that checks a mechanism may reach into the internals of the unit.
- Test each behavior at the lowest level that shows it. A test of a unit
  that builds other units checks only how it wires them.
- Put fixtures that several test files share in one testing unit, as the
  `code-structure` skill says.
- Assert what a caller sees. Assert a log line or a timer count only when
  nothing else shows the effect, and say so in a comment.
- Do not remove an assertion from a test. If an assertion looks redundant,
  report it instead.
- Do not patch platform objects such as `Request`. If a case needs it,
  keep the patch in one helper, and name the platform behavior it depends
  on.
- Stub the boundaries: the network, the clock, and the callbacks that other
  units pass in. Use fake timers for every wait.
- Follow the project's place and form for tests.

## 4. Verify

Run the formatter, the type checker, and the tests of the package.

## 5. Check the coverage

Run a coverage check on the units you tested, for example
`vitest run --coverage` or `cargo llvm-cov`. Look for obvious gaps: a
branch, a function, or an error path that no test reaches. Note each gap
for step 7, or say why it needs no test, for example dead code.

## 6. Run the mutation tool

A mutation tool changes one spot of the code at a time and runs the tests.
A change that no test catches survives. Use Stryker with its Vitest runner
in TypeScript, and `cargo mutants` in Rust. Limit the run to the units you
tested.

With Stryker, add the `json` reporter, and pass the report to
`scripts/stryker-survivors.py`. It sorts out the text survivors and lists
the others. If the project logs through its own logger, pass the logger
call with `--text`.

Sort each survivor into one of three kinds:

- Text: a log line or an error message. It needs no test.
- Equivalent: the change keeps the behavior, for example a guard that
  another guard covers. Say why in one line.
- Gap: the change alters behavior that no test checks. Note it for step 7.

If no mutation tool exists for the language, break the line that each weak
test guards by hand instead: a test that checks that something does not
happen, or a mechanism test of a race or a timer.

## 7. Close the gaps

Show the new cases from steps 5 and 6 as a nested checklist, in the form
of step 2, with the place and the survivor of each case. Wait for my
approval. Then write the tests, and prove each one: break the line again,
for example with `scripts/prove-vitest.py`, and the test must fail.

## 8. Report

Run the coverage check and the mutation tool again. Report both numbers
before and after step 7, the number of survivors of each kind, and each
gap with its new test.

## Tools that the project does not have

If the project has no coverage or mutation tool, add it only for the run,
and restore the dependency files afterwards. With pnpm, Stryker cannot
find its runner by name: pass the absolute path of the runner's entry
file in `plugins`.
