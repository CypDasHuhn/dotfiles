# AI queue await

`ai queue await` is an attached, one-shot wait command for an agent session. It
watches only the current Git repository's root `TODO-QUEUE.md` with
[`watchexec`](https://watchexec.github.io/), using a 750 ms save debounce. It
does not start an agent. When a pending item is added or its title materially
changes, it emits exactly one JSON event to standard output and exits.

The command establishes the current file as its baseline when it starts, then
reconciles it through Watchexec's startup event after the filesystem watch is
installed. State is saved outside repositories at
`${XDG_STATE_HOME:-~/.local/state}/dotfiles/ai-queue/<repository-sha256>.json`,
so restarts do not require a tracked or generated state file. `TODO-QUEUE.md`
must exist before starting the command.

Run the normal dependency bootstrap to install `watchexec`, then use:

```nu
ai queue await
```

The `gitignore` bootstrap module adds the pattern to Git's configured global
excludes file. It uses `core.excludesFile` when configured, otherwise Git's
XDG default (`$XDG_CONFIG_HOME/git/ignore` or `~/.config/git/ignore`), and
preserves existing rules.

## Supported `TODO-QUEUE.md` format

Only checklist rows are queue items. Every item must occupy one line, begin at
any indentation level, and use exactly one of these forms:

```markdown
- [ ] ID: Pending title
- [x] ID: Completed title
```

`[X]` is also accepted for a completed item. `ID` must be unique across all
queue rows and match `[A-Za-z0-9][A-Za-z0-9._-]*`; titles are trimmed and must
not be empty. A title may otherwise contain Markdown, including colons.
Headings, paragraphs, blank lines, and comments are ignored. A line beginning
with `- [` must be a valid queue item.

Only `[ ]` items participate in change detection. Editing, adding, or removing
completed items does not wake the waiter. Marking a completed item pending
does. For an existing pending ID, changing the trimmed title is material;
whitespace surrounding a title is not.

The emitted event is a single compact JSON object:

```json
{
  "event": "ai.queue.pending_changed",
  "repository": "/absolute/repository/path",
  "queue_file": "/absolute/repository/path/TODO-QUEUE.md",
  "detected_at": "2026-09-07T11:40:10+00:00",
  "items": [
    { "change": "new", "id": "TASK-42", "title": "Pending title" }
  ]
}
```

Several changes included in one debounced save are reported in the same event.

## Agent loop

After receiving an `ai.queue.pending_changed` event, an agent must immediately
start `ai queue await` again in the background before processing the reported
items. Every event includes this as `next_action`, so the listener remains
armed while work is in progress.
