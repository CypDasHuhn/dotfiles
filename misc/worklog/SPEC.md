# Worklog — Architecture Spec

## Sources

| Source | Mechanism | Scope |
|--------|-----------|-------|
| `git` | git-standup | per device |
| `teams_calls` | WebView2 IndexedDB via `ccl_chromium_reader` | per device |
| `calendar` | MS Graph `calendarView` endpoint | per device |
| `mail` | MS Graph `messages` endpoint | per device |
| `azure_devops` | `az devops` CLI | on demand |
| `browser_history` | SQLite export from browser profile | per device |
| `shell_history` | parsed from shell history file | per device |
| `llm_chats` | provider API (per configured provider) | per device |
| `personal_log` | `worklog log "..."` CLI insert | ad hoc |

**MS Graph auth:** `az account get-access-token --resource https://graph.microsoft.com` reuses the existing Azure CLI session. No separate OAuth flow.

Each source script outputs a JSON array. Every record shares this envelope:

```json
{ "source": "git", "device": "workstation", "date": "2026-08-31", "ts": "2026-08-31T09:12:00Z", "data": {} }
```

Records are uploaded to Nextcloud as `YYYY-MM-DD-device-source.json`. `ingest.nu` downloads all files matching the target date and upserts into SQLite.

---

## Source: browser_history

Raw browser history is too noisy to store or feed to Codex. A persistent **URL mask** filters it before anything reaches the DB. The mask grows over time — every rejection is a permanent filter, so noise decreases with use.

**Filtering is purely local and deterministic — no Codex involved.**

```
youtube.com           → blocked (entire domain)
reddit.com            → blocked by default
reddit.com/r/vue      → allowed (specific subreddit)
reddit.com/r/whoosh   → blocked (added after first encounter)
learn.microsoft.com   → allowed
```

Rules are evaluated top-to-bottom, most specific match wins. Only URLs that pass the mask are stored in the DB.

```sql
CREATE TABLE url_mask (
    pattern   TEXT PRIMARY KEY,  -- domain or domain/path prefix
    allowed   INTEGER,           -- 1=allow, 0=block
    note      TEXT
);

CREATE TABLE browser_history (
    id      TEXT PRIMARY KEY,
    date    TEXT,
    ts      TEXT,
    url     TEXT,
    title   TEXT,
    device  TEXT
);
```

When a new URL hits an unmatched domain/path, it is staged for a mask decision before being stored. The approval step handles this the same way as enrichment approvals.

---

## Source: shell_history

Raw shell history is too voluminous (potentially thousands of commands per day). Commands are filtered by a **novelty score** against a personal baseline — not by command type, but by how unusual the specific command+argument pattern is for this user.

```sql
CREATE TABLE command_baseline (
    pattern   TEXT PRIMARY KEY,  -- normalized: command + significant args, paths stripped
    count     INTEGER,
    last_seen TEXT
);
```

On ingestion, each command is normalized and looked up in `command_baseline`. Commands below a novelty threshold (high count, seen recently) are dropped. Commands above threshold are stored and the baseline is updated.

```sql
CREATE TABLE shell_events (
    id      TEXT PRIMARY KEY,
    date    TEXT,
    ts      TEXT,
    device  TEXT,
    command TEXT,               -- raw command
    pattern TEXT,               -- normalized pattern used for baseline lookup
    novelty REAL                -- score at time of ingestion
);
```

`cd ~/source/repos/cvm` → seen 200 times → score near zero, dropped.
`cd /etc/nginx/conf.d` → seen once → high novelty, stored even though it's just `cd`.

The same principle applies to any command: it is not what the command *is* but how anomalous it is *for this user*.

---

## Source: llm_chats

For each configured LLM provider (Claude, ChatGPT, etc.), the source script fetches the conversation list and checks `last_message_ts` against the cached value. Only chats with new messages since the last run are re-summarized.

```sql
CREATE TABLE llm_chat_cache (
    id              TEXT PRIMARY KEY,  -- provider-scoped conversation id
    provider        TEXT,
    title           TEXT,
    last_message_ts TEXT,
    summary         TEXT,              -- filled by a cheap summarization call to the same provider
    summary_ts      TEXT               -- when the summary was last generated
);
```

The summarization call is narrow: "summarize this conversation in 2-3 sentences, topic and outcome only." It runs per-chat, not per-day. Once a chat has no new messages, it is never re-summarized. Over time this table becomes a personal research log: topics explored, problems solved, tools investigated.

---

## Database Schema

### Control table

```sql
-- Always exactly one row. All filtered views read from here.
CREATE TABLE params (
    date    TEXT,   -- YYYY-MM-DD; NULL = no date filter
    project TEXT    -- project.id; NULL = all projects
);
```

No script passes a date argument into a view. Scripts set `params` once, then query views without arguments.

### Raw event tables

```sql
CREATE TABLE git_commits (
    id      TEXT PRIMARY KEY,
    device  TEXT, date TEXT, ts TEXT,
    repo TEXT, branch TEXT, subject TEXT, author TEXT
);

CREATE TABLE teams_calls (
    id              TEXT PRIMARY KEY,
    device          TEXT, date TEXT, ts TEXT,
    direction       TEXT,
    duration_s      INTEGER,
    recipient_name  TEXT,
    recipient_email TEXT
);

CREATE TABLE calendar_events (
    id              TEXT PRIMARY KEY,
    date TEXT, ts_start TEXT, ts_end TEXT,
    subject         TEXT,
    organizer_email TEXT,
    attendees       TEXT    -- JSON array of emails
);

CREATE TABLE mail (
    id           TEXT PRIMARY KEY,
    date TEXT, ts TEXT,
    subject      TEXT,
    sender_email TEXT,
    importance   TEXT,
    body_preview TEXT
);

CREATE TABLE personal_log (
    id        TEXT PRIMARY KEY,
    ts        TEXT NOT NULL,
    date      TEXT NOT NULL,
    device    TEXT,
    raw_text  TEXT NOT NULL,
    resolved  TEXT,     -- filled by enrichment pass
    certainty REAL
);
```

### Relational layer

Populated partly by structural inference (Azure DevOps, certainty=1.0) and partly by the Codex enrichment pass after human approval.

```sql
CREATE TABLE people (
    id    TEXT PRIMARY KEY,  -- email address
    name  TEXT,
    role  TEXT               -- 'customer' | 'colleague' | 'sysadmin' | 'manager' | ...
);

CREATE TABLE projects (
    id TEXT PRIMARY KEY,
    name TEXT
);

CREATE TABLE project_members (
    project_id TEXT REFERENCES projects(id),
    person_id  TEXT REFERENCES people(id),
    certainty  REAL,
    source     TEXT    -- 'azure_devops' | 'codex_inference' | 'manual'
);

CREATE TABLE project_repos (
    project_id TEXT REFERENCES projects(id),
    repo_path  TEXT,
    source     TEXT
);
```

### Enrichment staging

```sql
CREATE TABLE pending_enrichments (
    id        TEXT PRIMARY KEY,
    type      TEXT,      -- 'person_role' | 'project_member' | 'project_repo' | 'log_resolve' | 'url_mask'
    payload   TEXT,      -- JSON of proposed change
    certainty REAL,
    evidence  TEXT,
    approved  INTEGER    -- NULL=pending, 1=approved, 0=rejected
);
```

All Codex passes and the URL mask staging write here. The approval step is the single gate before any state changes commit to permanent tables.

### Views

All views auto-filter via `params`. No caller passes a WHERE clause.

```sql
CREATE VIEW v_day_events AS
    SELECT 'commit'  AS kind, ts, repo            AS context, subject                   AS summary, NULL             AS detail
    FROM git_commits      WHERE date = (SELECT date FROM params)
    UNION ALL
    SELECT 'call',        ts, recipient_name,                  direction,                    cast(duration_s AS TEXT)
    FROM teams_calls      WHERE date = (SELECT date FROM params)
    UNION ALL
    SELECT 'meeting',  ts_start, organizer_email,              subject,                      attendees
    FROM calendar_events  WHERE date = (SELECT date FROM params)
    UNION ALL
    SELECT 'mail',        ts, sender_email,                    subject,                      body_preview
    FROM mail             WHERE date = (SELECT date FROM params)
    UNION ALL
    SELECT 'log',         ts, NULL,                            coalesce(resolved, raw_text), NULL
    FROM personal_log     WHERE date = (SELECT date FROM params)
    UNION ALL
    SELECT 'browser',     ts, url,                             title,                        NULL
    FROM browser_history  WHERE date = (SELECT date FROM params)
    UNION ALL
    SELECT 'shell',       ts, pattern,                         command,                      cast(novelty AS TEXT)
    FROM shell_events     WHERE date = (SELECT date FROM params)
    ORDER BY ts;

-- Project-scoped: filters by params.project when set, via repo or person membership.
CREATE VIEW v_project_events AS
    SELECT e.kind, e.ts, e.context, e.summary, e.detail, pm.project_id
    FROM v_day_events e
    LEFT JOIN people pe          ON pe.id = e.context
    LEFT JOIN project_members pm ON pm.person_id = pe.id
    LEFT JOIN project_repos pr   ON pr.repo_path = e.context
    WHERE (SELECT project FROM params) IS NULL
       OR pm.project_id = (SELECT project FROM params)
       OR pr.project_id = (SELECT project FROM params);
```

---

## Pipeline

### Step 1 — Ingest

`ingest.nu --date YYYY-MM-DD`

- Downloads all `YYYY-MM-DD-*-*.json` from Nextcloud `device-work/`
- Dispatches by filename suffix to the correct upsert function
- Applies URL mask and baseline novelty filter during import for browser and shell sources
- New unmatched URLs are staged in `pending_enrichments` as `url_mask` proposals
- Idempotent; re-running is safe

### Step 2 — Structural enrichment (no Codex)

- Azure DevOps contributor list per project → `project_members` (certainty=1.0, source=`azure_devops`)
- Azure DevOps repo list per project → `project_repos` (certainty=1.0, source=`azure_devops`)
- LLM chat cache update: fetch new messages per provider, re-summarize changed chats only

Committed directly, not staged. These are ground truth.

### Step 3 — Semantic enrichment (Codex pass)

Input: `v_day_events` + current `people`, `projects`, `project_members`, `project_repos`, `llm_chat_cache`.
Output: JSON array of proposed enrichments only, no prose.

Codex resolves:

- `personal_log.raw_text` → people and entities in DB → `log_resolve`
- Mail/chat content → infer sender role or project affiliation
- Unknown call recipients → propose role from context
- Browser history entries → correlate with active work (e.g. Vue debugging page on day with Vue commits)
- Anomalous shell commands → infer what work was happening

### Step 4 — Approval

`worklog approve`

Presents all `pending_enrichments WHERE approved IS NULL ORDER BY certainty DESC`.

- `y` → applies change, sets `approved=1`
- `n` → sets `approved=0`, never shown again
- `s` → stays pending

Covers enrichments and URL mask proposals in one pass.

### Step 5 — Summarize

`summarize.nu --date YYYY-MM-DD`

1. Sets `params` for the date
2. Queries `v_day_events` — pre-joined, approved context
3. Formats as structured markdown document, one section per event kind
4. Calls Codex once with context + `prompt.md`
5. Codex writes prose; does not query DB, does not reason about relationships

---

## personal_log

```
worklog log "spoke to max about security tags"
worklog log "Mrs Krueger confirmed the feature works"
worklog log "reviewed nginx config with sysadmin, firewall blocking rollout"
```

- Timestamp and device recorded automatically
- No structure required
- Enrichment pass resolves against DB context: "max" → Max Reimes if a call exists that day
- "security tags" → branch `feature/security-tags` if active in a known repo
- Ambiguous resolutions staged at lower certainty, shown in approval step

---

## File layout

```
misc/worklog/
  SPEC.md
  collect.nu        orchestrates per-device source collection
  ingest.nu         downloads Nextcloud JSON, upserts into DB, applies masks
  enrich.nu         structural enrichment (Azure) + Codex semantic pass
  approve.nu        interactive pending_enrichments review
  summarize.nu      sets params, queries views, calls Codex for final summary
  prompt.md         summarization prompt
  prompt-enrich.md  enrichment pass prompt
  nextcloud.nu      WebDAV client (unchanged)
  cleanup.nu        Nextcloud cleanup (unchanged)
  db/
    schema.sql      all CREATE TABLE / VIEW statements
    init.nu         creates DB and applies schema.sql if not exists
  sources/
    git.nu          git-standup → JSON envelope
    teams_calls.nu  wraps extract.py → JSON envelope
    graph.nu        MS Graph calendar + mail → JSON envelopes
    azure.nu        az devops CLI → JSON envelope
    browser.nu      browser SQLite history export → JSON envelope (mask applied on ingest)
    shell.nu        shell history parser → JSON envelope (baseline applied on ingest)
    llm.nu          LLM provider chat list + selective re-summarization
  generated/        gitignored
    worklog.db
    summary.md
```

---

## v2 — Todo Tracker

This is the goal the summary pipeline is building toward. The enriched dataset that reconstructs the past also reveals what is incomplete. Most digital work leaves a trace — the todo tracker uses those traces to catch dropped commitments automatically.

### Value

A summary of what you did is nice to have. A list of what you promised but haven't finished, or what a customer asked for and never got a response to, is worth catching. That's the gap this closes.

### How it works

The same `v_day_events` data that feeds the summary is scanned for open signals and matched against closure signals across all sources:

| Opened by | Closed by |
|-----------|-----------|
| Customer mail asking for a feature | Reply mail, ticket created, or commit in relevant repo |
| PR opened | PR merged or closed |
| Ticket opened | Ticket resolved in Azure DevOps |
| Teams call where someone asked something | Follow-up mail, commit, or personal_log referencing it |
| `personal_log` "need to check X" | Later log entry, commit, or ticket mentioning X |

### State machine

```
open → in_progress → pending_feedback → done
            ↓
         ignored
```

Transitions are driven entirely by the todo prompt — not by schema rules. What counts as a valid closure signal is configurable. A personal_log entry like "Mrs Krueger confirmed the feature works" is enough if the prompt allows informal confirmation and Codex can connect her to the open item via the people and project tables.

Example chain:

```
customer mail asking about feature X
  → open:             "Respond to Mrs Krueger re: feature X"
  → in_progress:      branch feature/X created, commit activity seen
  → pending_feedback: feature merged, no customer response yet
  → done:             personal_log "Mrs Krueger confirmed feature works"
```

### Schema addition

```sql
CREATE TABLE todos (
    id          TEXT PRIMARY KEY,
    created_ts  TEXT,
    state       TEXT,       -- 'open' | 'in_progress' | 'pending_feedback' | 'done' | 'ignored'
    title       TEXT,       -- codex-generated, human-editable
    source_ref  TEXT,       -- id of the originating event
    project_id  TEXT REFERENCES projects(id),
    updated_ts  TEXT,
    update_note TEXT        -- what signal caused the last state change
);
```

Proposed state changes land in `pending_enrichments` (type `todo_state`) and go through the same approval step. Todos persist across days — they are not regenerated from scratch each run.

### Pipeline addition

A todo pass runs as a separate Codex call after enrichment, using `prompt-todo.md`. Input is `v_day_events` plus the current `todos` table. Output is a JSON array of proposed new todos and state transitions only — no prose.

