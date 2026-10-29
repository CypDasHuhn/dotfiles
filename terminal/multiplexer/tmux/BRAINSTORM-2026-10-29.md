# Tmux worktrees and related-session navigation — brainstorm

Temporary notes from 2026-10-29. Delete or promote into a real design doc once
the direction is settled.

## Goal

- One git worktree = one tmux session.
- Serious work never happens on `main`; `main` is a hub for looking around and
  quickfixes.
- Predictable layout: `~/workspaces/<repo>/<branch>`.
- Sessions of the same repo are linked (siblings) and reachable without
  remembering session names.
- Everything must degrade gracefully for non-git sessions.

## Worktree layout

Three options for the main worktree:

- **A — start here.** Main worktree stays at `~/repos/<repo>`; linked worktrees
  live at `~/workspaces/<repo>/<branch>`. Rule: `main` = `~/repos`, everything
  else = `~/workspaces`. Optional convenience symlink
  `~/workspaces/<repo>/main -> ~/repos/<repo>` (session root canonicalizes to
  `~/repos/<repo>`).
- **B — endgame.** Bare canonical clone at `~/repos/<repo>.git`; *all*
  worktrees, including `main`, under `~/workspaces/<repo>/<branch>`. No
  exceptions. Cost: one-time migration, and `~/repos/<repo>` stops being a
  working tree.
- **C — rejected.** Move the main checkout into `~/workspaces` by hand.
  `git worktree move` refuses the main worktree, and a manual move breaks the
  linked worktrees' `gitdir` files.

Core principle: `git worktree list --porcelain` is the source of truth for
*branch → path*. `~/workspaces/...` is only the **default for creation**. That
keeps agent-created worktrees discoverable even when they live somewhere else.

Path rules:

- Repo slug = basename of the **main worktree** (first `git worktree list`
  entry), or the bare repo path minus `.git`. Not the linked worktree's dir.
- Branch slug: flatten `feat/foo` → `feat-foo` to avoid the `feat` dir/file
  collision, or mirror slashes as nested dirs (open decision).
- Repo basename collisions (`api` in two orgs): fall back to `<owner>-<repo>`,
  or keep a common-dir → slug map in state.
- `~/workspaces/<repo>/` is never a session root; only branch dirs are.

## Branch-scoped identity

- Store `@workspace-branch` = the branch the worktree was created for. Path and
  session name derive from this, never from live `HEAD`.
- Live HEAD drift (merge, bisect, detached) is temporary: show a badge, do not
  rename the session or move the directory.
- Permanent rename (`git branch -m`) → explicit `wt rename`.
- One worktree per branch is enforced by git; `wt <branch>` should jump to the
  existing worktree instead of erroring.
- Optional reserved `_scratch` detached worktree per repo for merges and
  throwaway experiments, so branch dirs stay pure.

## Proposed `wt` helper family

Creation / navigation:

- `wt new <branch> [--from base] [--agent cmd]` — ensure worktree + session.
- `wt go <branch>` / `wt switch <branch>` — jump to worktree/session, create if
  missing.
- `wt home` — jump to the hub session (main worktree).
- `wt adopt [path]` — attach a session to an externally-created worktree.

Rotation / maintenance:

- `wt ascend [--as name] [--sync]` — rotate the hub's current branch into its
  worktree; return the hub to the default branch.
- `wt ls` — repo, branch, path, session?, dirty, ahead/behind, live-HEAD drift.
- `wt rm <branch> [--keep-branch] [--force]` — remove worktree + session,
  optionally delete branch.
- `wt rename <old> <new>` — rename branch + move worktree + rename session.
- `wt prune` — drop worktrees whose branch is gone/merged; kill orphan sessions.
- `wt sync [<branch>]` — fetch + rebase onto default (reuse
  `git-rebase-default`), optionally all.
- `wt scratch` — detached `_scratch` worktree for merges/experiments.

Guard rail: when the hub session's live branch != default, show a warning badge
in `status.nu` (`hub:feat-x — ascend?`) plus a bind to run ascend.

## Quick ascend

Goal: rotate unexpected work out of the hub into its real worktree, leaving the
hub on the default branch.

```
default := local branch for refs/remotes/origin/HEAD
           (fallback main / develop / --default)
current := git branch --show-current
```

Gotcha (verified): `git worktree add <path> <branch>` fails while that branch is
still checked out in the hub. The order is forced:

```
stash dirty  ->  switch hub to default  ->  worktree add  ->  pop stash in new worktree
```

`git stash` is repo-global; pushing in the hub and popping in the new worktree
works, including untracked (`-u`).

Case 1 — feature branch sitting in the hub:

```nu
if dirty: git stash push -u -m "ascend:($current)"
git switch $default                                   # frees the branch
git worktree add ~/workspaces/<repo>/<slug(current)> $current
if stashed: git -C <new> stash pop
# optional --sync: git reset --hard origin/$default (or merge --ff-only)
```

Case 2 — hub on default (or detached) with quickfix commits/changes
(`--as <name>`):

```nu
git branch $name HEAD                    # preserve commits before resetting hub
if dirty: git stash push -u -m "ascend:($name)"
git worktree add ~/workspaces/<repo>/<slug(name)> $name
if stashed: git -C <new> stash pop
git reset --hard origin/$default         # hub returns to remote head
```

"Local copy of remote head" ambiguity:

- Switch the hub to the local default branch only (`git switch main`), or
- Sync it to remote (`git reset --hard origin/main` / `merge --ff-only`).

Recommendation: switch-only in Case 1 with `--sync` opt-in; hard reset is
mandatory in Case 2, otherwise the quickfix commits remain on `main`.

Session integration: create/ensure the session at the new path
(`@workspace-branch`, name `<repo>/<slug>`), then switch the client there.
A shell cannot `cd` its parent, so switching sessions is the honest move. If
ascend runs from an agent/editor tab whose process cwd is still the hub, the
tool itself must `cd`; moving a window does not change a process's cwd.

Caveats:

- Ignored files (`node_modules`, `target/`) do not travel; new worktree starts
  cold. Consider `--link-caches`.
- Submodules are not initialized by `git worktree add`; run
  `git submodule update --init` if present.
- Detached hub → require `--as`, treat as Case 2.
- Rebase/merge in progress → abort with a clear message instead of stashing
  half a state.
- Stash pop conflict → abort, keep the stash, do not reset main.
- Windows/psmux: same commands, but test path handling.

## Git wrapper (`git-wt-ascend`)

Nushell command in `general/git.nu` (do not shadow `git`; a `git-*` PATH
extension can come later). `git-wt-ascend [branch]`:

1. Resolve the repo and main worktree (first non-bare entry in
   `git worktree list --porcelain`). Operate there even if invoked from a
   linked worktree.
2. `branch` defaults to the main worktree's current branch; detached without an
   argument is an error.
3. If `branch` is checked out in a linked worktree → error with its path.
4. If the main worktree is on `branch`:
   - Abort on merge/rebase/cherry-pick/bisect or unmerged paths.
   - Resolve the default branch from `refs/remotes/origin/HEAD` (fallback
     `main`, `master`, `develop`). If the local branch is missing, create it
     with `--track`. If it is checked out elsewhere, abort.
   - Stash if dirty: `git stash push -u -m "wt-ascend:<branch>:<epoch>"`.
   - `git switch <default>`; on failure, pop the stash and abort.
   - `git worktree add <path> <branch>`; on failure, switch back to `branch`,
     pop the stash, abort.
   - If stashed, `git -C <path> stash pop`; on conflict, keep the stash and
     report its ref (do not destroy the worktree).
5. If the main worktree is not on `branch`:
   - If the branch is not local → error.
   - `git worktree add <path> <branch>`.
6. Path: `~/workspaces/<repo>/<slug(branch)>`. `git worktree add` creates
   parents; `mkdir -p` the repo dir anyway.
7. Print the new path.

`--sync` resets the hub to `origin/<default>` after switching (Case 1); Case 2
(hub on default with quickfix commits) always hard-resets after branching the
work aside. `tws ascend [branch]` runs `git-wt-ascend`, then opens/switches the
session at the printed path. Windows: use `tws ascend`; a `.cmd`/`.ps1`
`git-wt-ascend` shim is optional.

## Move a tab to a worktree (rehome)

Needed when an agent turns a tab into a custom worktree that was not planned.

Mechanics (verified):

- `tmux move-window -s <window_id> -t '=<dest-session>:'` appends at the next
  free index; `renumber-windows on` cleans up.
- Moving the **last** window out of a session destroys that session.
- `@workspace-purpose` is a window option, so it travels with the window. The
  moved tab lands in the same purpose group automatically; stamp the source's
  current purpose if the tab has none.

Bind: `C-M-m` root / `m` in the `workspace-related` table. Fuzzy-pick the
destination from fzf. (Quick rehome from the pane's worktree is a later
convenience; the picker is the primitive.)

Picker contents should include sessions **and worktrees without sessions**:

```
[S] myrepo:main          /code/myrepo
[S] myrepo:feat-a        /code/myrepo.worktrees/feat-a
[+] myrepo:agent-xyz     /code/myrepo.worktrees/agent-xyz   (no session)
```

Picking `[+]` creates + initializes the session first. Reuse the fzf-tmux helper
in `pick-related` (`workspace.nu:792`). Preview with
`git -C <root> status -sb` is a nice-to-have.

Edge cases:

- Last window kills source → create a replacement shell window at the source
  root first, then move.
- Pane cwd != worktree (agent uses `-C`): fuzzy move still works; quick rehome
  won't trigger. That is correct, do not guess.
- Stale worktree (dir deleted): validate root; offer `git worktree prune` + kill
  orphan session.
- Follow or stay: follow the window to the destination by default; `--stay`
  keeps the client put.
- Windows/psmux: verify `move-window` support.

Note: `tws repin` already exists and re-anchors a whole session. Moving a tab is
the per-window counterpart; keep both.

## Related-session navigation (final)

No groups. Relations stay pairwise; worktree siblings are a derived overlay.

Model:

- `related(s) = (manual(s) ∪ calculated(s)) \ excluded(s)`.
- `calculated(s)` = sessions with the same non-empty `@workspace-git-common`
  and a different workspace id. Set `@workspace-git-common` when a session is
  created, repinned, or discovered on attach.
- `excluded(s)` = ids explicitly unlinked from a calculated relation; stored on
  the workspace record. Linking removes the id from `excluded`.
- The current session is included in the display but is not its own relation.

Ordering and centering:

- Sort `related(s)` by session name (ascending, case-insensitive).
- `n = |related(s)| + 1` (current included).
- Insert the current at index `p = floor(n / 2)` (0-indexed). The rest keep
  name order. `p` is the visual center; for even `n` the current sits just
  right of center.
- The current is re-centered after every switch, so the order re-forms around
  the new current. `j/k` therefore target the visual neighbors of the center,
  not a stable global list. Accepted: this is a carousel, not a traversal.
- Example, current `A`, relations `B C D`: `n=4, p=2` → `B C [A] D`.
  `k` → `C`, `j` → `D`. After `j`, current `D`: `A B [D] C`.

Display:

- Current: purple (`fg=#1a1b26,bg=#bb9af7,bold`).
- Pending: amber (`fg=#000000,bg=#e0af68,bold`), only when pending ≠ current.
- Manual relation: white (`fg=#ffffff,bg=#111111`).
- Calculated-only relation: dim (`fg=#a7a7c4,bg=#111111`).
- Both manual and calculated: manual style wins.
- Overflow: keep the current centered, truncate to
  `@workspace-related-max` (default 12) with `…` on each side.

Keys (`C-A` = Ctrl-Alt = tmux `C-M-`):

- Root: `C-M-h` / `C-M-l` cursor left/right; `C-M-j` / `C-M-k` direct
  next/previous; `C-M-a` link picker; `C-M-x` unlink pending; `C-M-m` move-tab
  picker.
- `C-M-h/l` start the pending cursor at the current (if none), move one step,
  enter the `workspace-related` table, and arm the 1s timeout.
- `C-M-j/k` switch immediately from the current, clear pending, stay in root.
- Table `workspace-related`:
  - `h` / `Left`: cursor left.
  - `l` / `Right`: cursor right.
  - `j` / `Down`: direct next.
  - `k` / `Up`: direct previous.
  - `Enter`: confirm pending (no-op if pending is the current).
  - `Escape`: cancel.
  - `x`: unlink pending (manual edge removed; calculated target added to
    `excluded`).
  - `a`: link picker.
  - `m`: move-tab picker.
- Cursor movement wraps. Direct next = `p + 1 mod n`; direct previous =
  `p - 1 + n mod n`. `n == 1` is a no-op.
- Timeout cancels (old picker behavior), it does not confirm. `j/k` is the
  fast path, so a cancelled timeout is harmless.
- `j/k` while a pending cursor exists: act from the current and clear pending.

Old bug this replaces: `left/right` never set pending, and `confirm`/`unlink`
read an always-empty option, so with 3+ relations both directions hit the same
middle index. The fix is to make `h/l` the only pending writer and have `j/k`
read the centered order directly.

Cleanup while here: wire the dead `workspace-related` table (or delete it),
remove the duplicated `status-*` functions in `workspace.nu`, and share the
ordering logic between `workspace.nu` and `status.nu` (extract to
`workspace-lib.nu`).

## Calculated relations

- Repo key: `git rev-parse --path-format=absolute --git-common-dir` from the
  session root. Stable across worktrees, distinct across clones.
- Set `@workspace-git-common` on every session at create/repin/attach. If a
  session lacks it, `related-records` computes it lazily from
  `@workspace-root` and writes the option back.
- `calculated(s)` = other sessions with the same non-empty key.
- `excluded` is the only persisted negative state; it exists so `unlink` can
  opt out of an otherwise automatic sibling. It is keyed by workspace id.
- Non-git sessions have no calculated relations and keep manual edges only.
- Worktrees are related whether or not they live under `~/workspaces`; the
  common-dir is the source of truth, not the path.

## Attach / pin discovery

Trigger: `tws [dir]` / `open-workspace`, not the tmux `client-attached` hook.
`tws` with no argument uses the client's `pane_current_path`.

1. Normalize the requested dir. For git, resolve `--show-toplevel`; the pin is
   the session whose `@workspace-root` equals that toplevel. For non-git, the
   pin is the session rooted at the dir itself.
2. If no pin exists, create one (`create-session`) and initialize it.
3. For a git pin, read `--git-common-dir` and set `@workspace-git-common`.
4. Enumerate `git worktree list --porcelain` from the toplevel. For each
   non-bare, existing path:
   - Find the session with that root; create it if missing.
   - Set `@workspace-git-common`, `@workspace-root`, `@workspace-branch`
     (empty for detached).
   - Session name: `<repo>/<slug(branch)>`; detached:
     `<repo>/detached-<short-sha>`.
5. Switch to the pin's session.
6. Gate auto-creation on `@workspace-auto-worktrees` (default `on`). Skip
   prunable/missing paths and bare entries.
7. The related set is derived from the common-dir, so all discovered worktrees
   are siblings without writing edges.

## Verified technical facts

- `git rev-parse --path-format=absolute --git-common-dir` is identical across
  all worktrees of a repo → stable group key.
- `git worktree list --porcelain` first entry is the main worktree, or a `bare`
  entry.
- `git worktree move` works on linked worktrees, refuses the main worktree.
- Manually moving the main checkout breaks linked worktrees' `gitdir` files.
- `git worktree add <path> <branch>` fails if the branch is checked out
  elsewhere (including the hub).
- `git stash` is repo-global; push in one worktree, pop in another works.
- `git worktree add` runs the `post-checkout` hook inside the new worktree.
- `tmux move-window -t '=<session>:'` appends at the next free index; moving the
  last window destroys the source session.
- Modern tmux allows `/`, `.`, `:` in session names; exact targets still want
  the `=` prefix.

## Decisions (best-effort, 2026-10-29)

- Layout: A. Main stays `~/repos/<repo>`; linked worktrees under
  `~/workspaces/<repo>/<branch>`. Bare-clone endgame (B) is deferred.
- Branch slug: flatten `/` → `-` for both the directory and the session name.
- Hub after ascend: switch-only by default; `--sync` resets to remote default.
  Case 2 (quickfix commits on main) always resets.
- Related navigation: pairwise + calculated; current centered at
  `p = floor(n/2)` (0-indexed); `j/k` direct neighbors, `h/l` pending cursor +
  Enter; timeout cancels; no groups.
- Ascend from a non-shell tab: switch sessions; do not move the tab.
- Move/ascend: follow the destination by default; `--stay` is optional.
- Last-window move: create a replacement shell window in the source, then move.
- Code placement: `git-wt-ascend` as a git extension for the git primitive;
  `tws ascend` and the `wt` family in nushell/tmux for session integration.
- Calculated relations: derived from `@workspace-git-common`; `excluded` is
  the only persisted negative state.
- Attach trigger: `tws [dir]`; pin = session at the git toplevel (or the dir
  for non-git); auto-create worktree sessions unless
  `@workspace-auto-worktrees` is `off`.
- Unify the duplicated related/status helpers in `workspace-lib.nu`.

## Code map

- `terminal/multiplexer/tmux/scripts/workspace.nu`
  - `related-records` (604), `select-related` (723), `select-session` (674),
    `move-to-session` (475), `open-workspace` (542), `repin-workspace` (575),
    `pick-related` (774), pending/timeout helpers (616-672, 866-893)
  - duplicated `status-*` (899-970) — dead, theme uses `status.nu`
  - add: centered ordering, `j/k` direct, `h/l` pending, attach discovery,
    move-tab picker, `@workspace-git-common` / `excluded`
- `terminal/multiplexer/tmux/scripts/workspace-lib.nu` (new) — shared
  `session-records` / `related-records` / ordering used by `workspace.nu` and
  `status.nu`
- `terminal/multiplexer/tmux/scripts/status.nu` — status bar rendering; include
  current at center, dim calculated-only siblings, truncate to
  `@workspace-related-max`
- `terminal/multiplexer/tmux/scripts/purpose.nu` — purpose select/cycle
- `terminal/multiplexer/tmux/keybindings.conf` — `C-M-h/l/j/k/a/x/m`, live
  `workspace-related` table, remove the dead `workspace-session` table
- `terminal/multiplexer/tmux/theme.conf` — 3-line status formats
- `terminal/multiplexer/tmux/options.conf` — `@workspace-*` globals, hooks; add
  `@workspace-auto-worktrees`, `@workspace-related-max`
- `shell/modules/nushell/tmux.nu` — `tws` / `tmux-workspace`; add `tws ascend`
- `shell/modules/nushell/general/git.nu` — existing git helpers
  (`git-rebase-default`, `git-rotate-branch-diff`); add `git-wt-ascend` here
  (a nushell command, not a PATH shadow of `git`)

## Implementation status (2026-10-29)

Done:

- `related(s) = manual ∪ calculated − excluded`; calculated via
  `@workspace-git-common`.
- State schema keeps `excluded`; `unlink` on a calculated sibling adds an
  exclusion, and `link` clears it.
- Name-sorted order with the current inserted at `floor(n/2)` (0-indexed).
- `C-M-h/l` cursor + Enter; `C-M-j/k` direct; 1s timeout cancels; live
  `workspace-related` table; dead `workspace-session` table removed.
- `status.nu` renders current/pending/manual/calculated and truncates to
  `@workspace-related-max` (default 12).
- `C-M-m` / `m` opens an fzf picker to move the current tab to another session;
  it creates a replacement shell window when moving the last window.
- `@workspace-git-common` is set on init/repin; `@workspace-auto-worktrees`
  exists but is not consumed yet.

Next:

- Attach/pin discovery (`tws [dir]`): resolve the git toplevel, create missing
  worktree sessions, set branch/common options.
- `git-wt-ascend` (nushell command in `general/git.nu`) and `tws ascend`
  (calls it, then opens/switches the session).
- Worktree session naming (`<repo>/<slug(branch)>`) and the worktree picker
  entries in the move-tab picker.
