---
name: git-review
description: Use when preparing a branch for human review with git-review, especially inspecting changes, assigning fragments to existing groups, and verifying review state.
---

# git-review

Use `git-review` to prepare review data for a human. The normal agent task is
to inspect the fragment inventory and assign source fragments to review groups.
This does not accept the changes.

## Agent setup workflow

```sh
git-review status --no-init --json
git-review changes --json
git-review group list --json
```

Use `git-review status` first when the review state may already exist. It shows
the work commit, reviewed state, comparison base, and pinned base. Do not run
`init` again on an existing review unless changing the review base is intended.

`changes --json` returns unaccepted source fragments. Each fragment is
identified by its commit, path, and source diff coordinates. `group list --json`
returns the available groups and their fragment assignments.

## Assign fragments

Assign each related fragment to an existing group with its exact ID:

```sh
git-review group assign \
  --name "mapping foundations" \
  --fragment <fragment-id>
```

Use `fragment inspect --commit <commit> --json` or
`fragment list --unassigned --json` to locate IDs. A selector can assign
fragments across commits without copying IDs:

```sh
git-review group assign \
  --name "mapping foundations" \
  --path-glob 'redispatch-api/**/Mapping/**'
```

Use existing group names from `group list` when they fit. If the user asks for
a dedicated group, assigning the first fragment to a new name creates that
group; there is no separate create step. Selectors preserve existing
assignments unless `--reassign` is supplied. Use `--dry-run --json` before
broad assignments.

Preserve existing assignments. Before assigning a fragment, compare its exact
ID and source commit/path against the groups. Do not move an already assigned
fragment merely because the file also contains the current task.

The review model is fragment-based against source commit diffs and a pinned
comparison base. Fragment IDs are stable across later line drift, but a later
edit can make a fragment ambiguous or unlocatable; git-review reports that
failure rather than silently applying the wrong edit. Changing only the working
tree or index does not add records to `changes --json`; capture the intended
work in a review commit first.

## Verify the setup

```sh
git-review group view --name "mapping foundations"
git-review group project --name "mapping foundations"
git-review group list --json
git-review fragment list --summary --json
git-review status --no-init --json
```

Confirm that every intended fragment appears in the expected group. Stop here
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
git-review status --no-init --json
git status --short
```

Use `status --no-init` for inspection. Initialize explicitly when a review
session is intended.

Group assignments update review-session metadata under `.git/git-review`.
Agents may need permission to write that repository metadata even when the
source files themselves are writable.

When the task is only to set up review data, do not run `accept`, `group
accept`, or other review-state mutations. Finish by reporting the groups and
fragment counts, plus any fragments that could not be assigned or located.
