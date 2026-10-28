---
name: git-review
description: Use when preparing a branch for human review with git-review, especially inspecting changes, assigning hunks to existing groups, and verifying review state.
---

# git-review

Use `git-review` to prepare review data for a human. The normal agent task is
to inspect the diff and assign each hunk to a review group. This does not accept
the changes.

## Agent setup workflow

```sh
git-review status
git-review changes --json
git-review group list --json
```

Use `git-review status` first when the review state may already exist. It shows
the work commit, reviewed state, comparison base, and pinned base. Do not run
`init` again on an existing review unless changing the review base is intended.

`changes --json` returns the hunks to classify. Each hunk includes its path and
the old and new line coordinates. `group list --json` returns the available
groups and their current assignments.

## Assign hunks

Assign each related hunk to an existing group with its exact coordinates:

```sh
git-review group assign \
  --name "mapping foundations" \
  --path redispatch-api/src/Mapping/Mapper.cs \
  --old-start 132 \
  --old-lines 4 \
  --new-start 132 \
  --new-lines 5
```

Repeat the command for every hunk. A new file uses zero old lines and starts
at line one in the new file:

```sh
git-review group assign \
  --name "mapping foundations" \
  --path src/Mapping/MapperOptions.cs \
  --old-start 0 \
  --old-lines 0 \
  --new-start 1 \
  --new-lines 12
```

Use existing group names from `group list` when they fit. If the user asks for
a dedicated group, assigning the first hunk to a new name creates that group;
there is no separate create step. Keep related implementation, support, and
test hunks together when they represent one reviewable change.

Preserve existing assignments. Before assigning a hunk, compare its exact
`path`, `oldStart`, `oldLines`, `newStart`, and `newLines` coordinates against
the groups. Do not move an already assigned hunk merely because the file also
contains the current task.

The review model is hunk-based against the review work commit and comparison
base. A later edit inside a large added-file hunk cannot be assigned separately
from that hunk. Likewise, changing the working tree or index alone may not add
new records to `changes --json`; make sure the intended work is captured in the
review work commit before assigning it, then rerun `changes --json`.

## Verify the setup

```sh
git-review group view --name "mapping foundations"
git-review group list --json
git-review status
```

Confirm that every intended hunk appears in the expected group. Stop here
unless the user explicitly asks for an accept operation.

## Accepting changes

These commands change review state and are separate from assigning groups:

```sh
git-review accept --path src/api/UsersController.cs --subject "review API changes"
git-review group accept --name "mapping foundations" --path src/api/UsersController.cs
```

Do not run either command during agent review-data setup unless the user asks
for changes to be accepted.

## Review-state recovery

```sh
git-review undo
git-review history
git-review reset --commit <commit>
```

Use `undo` to reverse the previous review-state action, `history` to inspect
review history, and `reset` to move the review state back to a specific commit.

## Operational notes

```sh
git status --short
git-review status
git status --short
```

In practice, `git-review status` may capture current working-tree changes into
the tool's review work commit. Check normal Git status before and after using
the tool so this state transition is visible.

Group assignments update review-session metadata under `.git/git-review`.
Agents may need permission to write that repository metadata even when the
source files themselves are writable.

When the task is only to set up review data, do not run `accept`, `group
accept`, or other review-state mutations. Finish by reporting the groups and
hunk counts, plus any coarse hunks that could not be split further.
