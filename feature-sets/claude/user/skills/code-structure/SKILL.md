---
name: code-structure
description: Rules for where code goes and what to call it. Use before you create, move, split, or name a module, file, or folder, or when the user asks how to organize or restructure a codebase.
---

# Code structure

Place and name code so that a maintainer understands the codebase from the
folder tree alone. The tree must show the real ownership and the real
direction of dependencies.

The rules aim to let each component and each boundary move into its own
package later, with changes to import paths only.

These rules apply to code in any language and at any scale. If the project
rules say something else, the project rules win.

## Vocabulary

- A unit is any module, file, or folder.
- A collection groups separate things of one kind. Every member is that kind
  of thing, for example `services/` with one service per member.
- An implementation groups the parts of one thing. Every member is a part of
  that thing, for example `task_queue/` or `engine/`.
- Some names only say what kind of thing a unit holds, for example `types`,
  `dto`, or `service`. Inside an implementation, such a name marks one part
  of the parent, not a collection. `api/http/types` is the types of the HTTP
  boundary, in the same way that `authentication/dto` is the DTOs of
  `authentication`.
- The configuration is the settings model and the code that reads it, for
  example a config file reader.
- The composition root builds the running components from the settings and
  holds them. It is the one place where the components come together. The
  boundaries reach the components only through its handle.

## Rules

1. Lean root. A root holds only units that no other unit owns at run time
   and that have a role of their own: the boundaries (the units the host or
   caller calls into) or a collection of them, the composition root, the
   configuration, and the components. The core is a component. A layer that depends on nothing else in the codebase is a
   component too, even if another unit holds its data at run time. At the
   top-level root, the components go in a `components/` collection.
   Collections that serve the root, such as `tests/`, may sit next to them.
   Everything else nests under its owner.
2. A collection holds only members of its kind, plus code that only its
   members share, such as conversions. Name that shared code by its role,
   not `common`. The first level of an implementation is a root in itself,
   so rule 1 applies to it again.
3. Place a unit by where it lives and works at run time. Who constructs it
   does not count. The composition root builds and holds every component, so
   neither its imports nor its ownership decides placement.
4. Place a unit by its role, not by who holds a reference to it. A unit
   whose content does not match its name points to misplaced code. A helper
   that imports a higher layer is not a helper. Test fixtures are their own
   kind: they go in a testing unit and stay out of the production API.
5. Leave room for growth. Put a unit at the widest scope it can grow into,
   not the narrowest scope it fits today.
6. Interfaces. An interface unit is one part of its parent. Its own file
   holds the interface and the helpers that the variants share, such as a
   registry. Each variant gets one file below it. This applies only if the
   variants belong to the same layer. If a lower layer defines an interface
   for higher layers to plug into, each implementation lives with its
   implementer.
7. Siblings that share a prefix for parts of one thing point to a missing
   parent. Example: `x_handler` and `x_registry` become `x` and
   `x/registry`. A shared role suffix, such as `task_queue_service`, applies
   a collection through the file name, which is fine. Use one method per
   codebase: folder or suffix.
8. Dependencies point one way. Siblings never form a cycle, also not the
   members of a collection.
   - Shared vocabulary, such as IDs, lives with the component that creates
     the thing it names. The component's own file is its contract. If
     several components create or own the thing, the thing is a component
     of its own, named after the concept.
   - A boundary is self-contained: its contract types live inside it. Inner
     code never depends on the boundary's entry points. Entry points only
     forward calls. Whether inner code may use the contract types is a
     decision, see "Decisions".
   - A boundary depends on the handle of the composition root, the
     configuration, and the contracts of the components. It never depends
     on the parts of the components.
   - A boundary creates the handle from its settings. It never creates the
     parts of the components.
9. Use explicit import paths. No re-exports and no barrel files, so each
   import shows where the item lives.
10. Attach behavior to the type it acts on: make it a method or an
    associated function, next to the type definition. If a unit needs
    behavior on a type that it does not own, give that unit its own type or
    a trait. A public function always belongs to a type or a trait. A free
    function stays internal to its unit, and it exists only for one of
    three reasons: an internal helper, removing duplication, or splitting a
    long function to a readable length.
11. Back every placement with a reason based on dependencies or ownership.
    If I refute the reason, drop the placement.
12. In Rust, a module with children uses `x/mod.rs`. Prefer `pub` items in
    private modules over `pub(crate)`. Then a move into its own package
    needs no visibility edits, and no item leaks into the public API.
    Whether a unit is a package is a decision, see "Decisions".

## Decisions

Decide these once per project. Record the choice in the project rules, so
that every session applies the same one.

### Types in the core: choose one

- **A. Contract types.** The core uses the types of a boundary directly. No
  conversions. Choose this for one boundary, for example a binding crate
  around one library, usually a small self-contained project.
- **B. Borrowed domain types.** The core borrows the types of one other
  layer as its domain types, for example a layer below it. The boundaries
  convert their contract types to those. One conversion per boundary. The
  shape of the borrowed layer leaks into the core, and a change there
  reaches every boundary. Choose this if it is good enough and the borrowed
  layer is stable.
- **C. Domain types.** The core has its own types. Each boundary converts
  its contract types to them and back, and so does each layer below the
  core. The core never sees the types of another layer. Choose this for
  several boundaries, a large modular app, or a boundary that will move
  into its own package.

If you are not sure, ask the user.

### Packages or folders: propose, the user decides

For each component and each boundary, propose whether it is its own package
or a folder. Give the reason for each package. The user makes the decision.

Reasons for a package:

- The project builds several artifacts with different dependency sets, for
  example a binary, a web API, and a mobile library.
- The unit ships on its own, for example a library that you publish.
- The unit has platform-specific dependencies.
- The unit is test-only.
- Review finds a broken direction, or a second consumer appears.
- Builds get slow.

Without a reason, propose a folder. If a reason appears later, propose the
change again.

## Example

A print server with a REST API and a CLI. Folders end in `/`. A name that
appears as both `x` and `x/` is a unit with its own file and children.

```text
src/
  app               composition root: builds pdf, spooler and license from Settings, holds them, gives the boundaries one handle (rules 1, 3)
  config/           configuration (rule 1)
    settings        the Settings model
    file            reads the config file into Settings
  api/              collection: one member per boundary (rules 1, 2)
    http/           boundary: the REST API (rule 8)
      routes        entry points, only forward to the app handle (rule 8)
      types         request and response types, one part of the boundary (vocabulary)
    cli/            boundary: the command line (rule 8)
    convert         conversions that only http and cli share (rule 2)
  components/       collection: one member per component (rules 1, 2)
    pdf/            independent layer: renders documents, imports nothing else (rule 1)
    spooler/        the core: queues and runs print jobs, uses pdf; its own file holds JobId (rules 1, 8)
      queue         job queue with cancel and retry
      workers       the worker pool of the spooler (rule 3)
      license       license renewal, runs while the server lives (rules 3, 4)
      os            printer discovery through CUPS or the Windows spooler, can grow into other OS concerns (rule 5)
      printer       interface, the registry that its variants share, and PrinterId (rules 6, 8)
      printer/
        ipp         variant: network printer over IPP
        usb         variant: local USB printer
        pdf_file    variant: writes a PDF file
      tests/        collection at the root of the spooler implementation (rule 2)
```

Rejected placements, and why:

- Wiring in `config`: `config` describes the settings, and `app` builds
  from them (rule 4).
- The components under `app`: `app` holds them only because it is the
  composition root (rule 3).
- `license` under `app`: `app` only constructs it (rule 3).
- `ids` at the root: an ID lives with the component that creates the thing
  it names (rule 8).
- `license` under `printer`: printers check the license, but its role is
  licensing, not printing (rule 4).
- `os` under `printer`: it can grow past printer discovery (rule 5).
- `types` at the root: the boundary is self-contained (rule 8).
- `convert` in the core: it is boundary code, not part of the core domain
  (rule 4).
- `convert` named `common`: the name does not say what the unit holds
  (rule 4).
- A root `utils/` that holds the test fixtures: fixtures are their own kind
  (rule 4).

## How to apply

Before you add or move a unit, answer three questions:

1. What does it do?
2. Who owns it at run time?
3. Does it sit in a collection or at the root of an implementation?

Place and name the unit from those answers. Give the answers with the
placement.
