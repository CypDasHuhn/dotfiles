---
name: csharp
description: Use when editing C# source, tests, or related project files. Covers formatting, tests, code style, null handling, regions, and library reuse.
---

# C# Editing

- Use `csharp-ls` via `lsp-bridge`; run `dotnet format` when available.
- Run the relevant tests after behavior changes; build/test the affected project
  before finalizing when the repo supports it.
- Ternary only when short and obvious; otherwise extract the condition into a
  clearly named boolean.
- `var` when the RHS type is obvious, explicit type otherwise; keep the file's
  existing nullable style.
- Guard clauses for required values; `ArgumentNullException.ThrowIfNull` at
  public entry points; no null checks that just repeat a guaranteed contract.
- `#region`/`#endregion` only for large or dense sections, not small blocks.
- Readable top-to-bottom; extract dense logic into named helpers/methods/types;
  explicit names over cleverness.
- Reuse the repo's DI/options/logging/data-access/test patterns. No new
  framework/ORM/mediator unless already used or explicitly requested; prefer the
  simplest abstraction.
