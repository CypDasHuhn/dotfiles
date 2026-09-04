---
name: vue-typescript
description: Use when editing Vue single-file components or related TypeScript code. Covers script setup, control flow, Tailwind styling, regions, and Pinia/DevExtreme usage.
---

# Vue + TypeScript Editing

## Purpose

Use this guide when editing Vue single-file components and related TypeScript
code.

## Required Workflow

- Use VueLSP via `lsp-bridge`.
- Use `typescript-language-server` via `lsp-bridge`.
- Run `eslint`.
- Run `prettier`.

## Required Conventions

### Script Setup

- Always use `<script setup lang="ts">`.
- Do not introduce the old Vue API style unless the file already depends on it
  and migrating it is out of scope.

### Control Flow

- Avoid complex ternaries.
- Only use short, obvious ternaries.
- When branching logic is non-trivial, extract conditions into clearly named
  variables before rendering or branching on them.

### Styling

- Prefer Tailwind over custom CSS.
- Only add CSS when Tailwind is not a natural or reasonable fit.
- Keep styling lean unless the task explicitly calls for heavier visual work.

## Preferred Structure

### Regions

Use regions to mark larger logical sections when a component contains multiple
concerns or dense logic.

```vue
<template>
  <!-- region User Handling -->
  <div>...</div>
  <!-- endregion -->
</template>

<script setup lang="ts">
// region Complicated Logic
test();
// endregion
</script>
```

Do not add regions for very small or obvious sections.

## Library Guidance

- Prefer Pinia for shared state across multiple components or views.
- Prefer DevExtreme when it matches existing UI patterns in the project.
- Do not introduce Pinia or DevExtreme for small local-only problems that are
  simpler without them.

## Editing Heuristics

- Keep component logic readable from top to bottom.
- Extract repeated or dense logic into named helpers, composables, or stores
  when that reduces cognitive load.
- Avoid inline template expressions that are difficult to scan.
- Favor explicit names over compact cleverness.

## Research

- When library behavior is unclear, use the configured MCP server for research
  before guessing.
