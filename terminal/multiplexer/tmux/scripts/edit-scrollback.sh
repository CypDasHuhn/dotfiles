#!/usr/bin/env bash

set -euo pipefail

pane_id=${1:-}
if [[ -z "$pane_id" ]]; then
	pane_id=$(tmux display-message -p '#{pane_id}')
fi

editor=${EDITOR:-vi}
tmp_file=$(mktemp "${TMPDIR:-/tmp}/tmux-scrollback-XXXXXX.txt")

# -S - / -E - capture the full history buffer, not just the visible screen.
tmux capture-pane -p -t "$pane_id" -S - -E - >"$tmp_file"

tmux new-window -n scrollback "$editor '$tmp_file'; rm -f '$tmp_file'"
