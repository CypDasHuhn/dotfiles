---
name: vue-typescript
description: Use when editing Vue single-file components or related TypeScript code. Covers script setup, styling, regions, and Pinia/DevExtreme usage.
---

# Vue + TypeScript Editing

- Always `<script setup lang="ts">`; no legacy Vue API style unless already
  present and migrating is out of scope.
- Use VueLSP + `typescript-language-server` via `lsp-bridge`; run `eslint` and
  `prettier`.
- Ternary only when short and obvious; otherwise extract the condition into a
  named variable.
- Tailwind over custom CSS; add CSS only when Tailwind is not a natural fit;
  keep styling lean.
- `#region`/`endregion` for larger logical sections only.
- Pinia/DevExtreme only when they fit existing patterns and the state is
  cross-component; not for small local problems.
- Readable top-to-bottom; extract dense logic into helpers/composables/stores;
  avoid hard-to-scan inline template expressions.
