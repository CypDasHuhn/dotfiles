---
name: csharp
description: Use when editing C# source, tests, or related project files. Covers required workflows, control flow, types, null handling, regions, and editing heuristics.
---

# C# Editing

## Purpose

Use this guide when editing C# source, tests, and related project files.

## Required Workflow

- Use `csharp-ls` via `lsp-bridge`.
- Run the project formatter or `dotnet format` when available.
- Run the relevant tests after behavioral changes.
- Prefer building or testing the affected project before finalizing changes when
  the repository supports it.

## Required Conventions

### Control Flow

- Avoid complex ternaries.
- Only use short, obvious ternaries.
- When branching logic is non-trivial, extract conditions into clearly named
  variables before branching on them.

### Types

- Prefer explicit types when the right-hand side is not obvious.
- Use `var` when the type is obvious from the initializer or when the explicit
  type adds noise.
- Keep nullable annotations and null checks consistent with the file's existing
  style.

### Null Handling

- Prefer guard clauses for required values.
- Use `ArgumentNullException.ThrowIfNull` or equivalent existing project
  patterns for public entry points.
- Do not add defensive null checks that obscure the intended control flow when
  the caller contract already guarantees a value.

### Folds

Use `#region` and `#endregion` for folding when a file has multiple substantial
sections or dense logic.

Do not add regions for very small or obvious blocks.

### Editing Heuristics

- Keep method and class logic readable from top to bottom.
- Extract repeated or dense logic into named helpers, private methods, or
  dedicated types when that reduces cognitive load.
- Favor explicit names over compact cleverness.
- Prefer small, intention-revealing methods over large blocks of imperative
  code.

## Library Guidance

- Prefer the project's existing patterns for dependency injection, options,
  logging, and data access.
- Prefer the simplest workable abstraction for the task at hand.
- Do not introduce a new framework, ORM, or mediator layer unless the codebase
  already uses it or the task explicitly calls for it.
- Prefer existing test frameworks and assertion styles already in the repo.

## Research

- When library behavior is unclear, use the configured MCP server for research
  before guessing.
