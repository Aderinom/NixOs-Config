# Code layout

- Split a function body into thoughts. A thought is one continuous
  operation with one goal, for example "turn the PEM into a list of
  certificates".
- Put one blank line between two thoughts. Put no blank line inside a
  thought.
- If a block closes with `}`, put a blank line after it. Skip the blank
  line before `else`, before another `}`, and where the next line
  continues the same thought.
- If a function body has more than one thought, put a very short comment
  above each thought. Name the goal in a few words, not the next call.
- Skip the comment if the thought is one statement and its first line
  already names the goal, for example `let accepted = handshake(...)`.
  Keep it if it adds a fact that the first line does not show.
- A comment that gives a reason always stays.
- Do not put a `match` or an `if` inside a returned expression, for
  example `Ok(match ...)` or `return if ...`. Bind the result to a named
  variable first, then return the variable.
- If a helper function has one caller, nest it inside that caller. Put it
  at the bottom of the caller. In Rust, end the body with `return ...;` so
  that the item can follow.
- If several helpers serve one function, group them with that function
  as associated functions of a unit struct. Use the struct as a namespace.
  Do not add a `mod` for this.
