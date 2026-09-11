---
name: no-comments
description: Use whenever writing, editing, or refactoring code in any language. Enforces a strict no-comments default and requires asking before adding any comment.
---

# No Comments by Default

- Write code with **no comments**. This is the default for every language.
- A comment is allowed only when the code is genuinely not understandable
  without it: a non-obvious *why*, misleading or contradictory context as an example. Ask the user for confirmation first then.
- Never add comments that restate what the code does, narrate sections, label
  obvious blocks, or explain something a competent reader already sees.
- If you believe a comment is warranted, **do not add it silently**. Leave it
  out, then at the end of your response call it out and ask the user whether to
  include it.
- When the user explicitly asks for a comment, add it.
