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
- Do not pass the result of a call that does work, such as an `await` or
  an RPC, straight into another call. Bind it to a named variable first.
- If a helper function has one caller, nest it inside that caller. Put it
  at the bottom of the caller. In Rust, end the body with `return ...;` so
  that the item can follow.
- If several helpers serve one function, group them with that function
  as associated functions of a unit struct. Use the struct as a namespace.
  Do not add a `mod` for this.
- Name a function by what it does, not by what it returns: `buildQueries`,
  not `builtQueries`. A getter that only returns held state is the
  exception, for example `currentToken()`.

## Order of items in a file

- Give each type its own group: a struct, enum, or type alias, with all
  of its impls. Put one blank line between two groups and no blank line
  inside a group.
- Put the impls of a type directly after the type, with no other item
  between them. An `impl Trait for Type` goes with the type, not with the
  trait.
- Traits that belong together, such as a read trait and its `Mut` form,
  share one group.
- Order the groups by what belongs together, not by their kind. Do not
  collect all types first and all traits after them.
- A *concept* is a main type with the types derived from it, their
  traits, and their helper functions. Order the groups of a concept in
  this sequence:
  1. The main type, for example the owned model.
  2. The types derived from it, for example its borrowed form.
  3. Their traits.
  4. Their free helper functions.
  5. The types that the main type holds as parts, in the order of its
     fields.
- Order the concepts of a file in the same sequence. A trait or a helper
  function that several concepts share is step 3 or 4 of the file.
- If the main item of a concept is a function, such as an HTTP handler,
  and its request and response types sit in the same file, put the types
  above the function.

  In a large project, the types can also live in a unit of their own.
- If two concepts in a file do not share a main concept, the
  `code-structure` skill decides if they move into units of their own.

Example:

```rust
// Concept Packet, step 1: main type.
pub struct Packet { /* ... */ }
impl Packet { /* ... */ }
impl Encode for Packet { /* ... */ }
impl Addressed for Packet { /* ... */ }

// Concept Packet, step 2: derived type.
pub struct PacketRef<'a> { /* ... */ }
impl Encode for PacketRef<'_> { /* ... */ }

// Concept Packet, step 3: traits.
pub trait PacketExt { /* ... */ }
pub trait PacketExtMut: PacketExt { /* ... */ }

// Concept Packet, step 4: helper, used by the `Encode` impls of Packet
// and PacketRef.
fn header_size(/* ... */) -> usize { /* ... */ }

// File, step 2: concept UdpPacket, derived from Packet.
pub struct UdpPacket { /* ... */ }
impl Addressed for UdpPacket { /* ... */ }

// File, step 3: trait that Packet and UdpPacket share.
pub trait Addressed { /* ... */ }
```
