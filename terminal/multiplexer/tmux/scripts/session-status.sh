#!/usr/bin/env bash

set -euo pipefail

current_session=${1:-}
if [[ -z "$current_session" ]]; then
	current_session=$(tmux display-message -p '#S')
fi

# Set by session-select.sh while Shift+Alt browsing is in progress; empty
# once confirmed (Enter) or cancelled (Escape).
pending_session=$(tmux show-option -gqv @session_pending 2>/dev/null || true)

session_format=$'#{session_last_attached}\t#{session_name}'
session_rows=$(tmux list-sessions -F "$session_format")

separator=''
while IFS= read -r session_row; do
	session_name=${session_row#*$'\t'}
	if [[ -z "$session_name" ]]; then
		continue
	fi

	printf '%s' "$separator"
	if [[ -n "$pending_session" && "$session_name" == "$pending_session" && "$pending_session" != "$current_session" ]]; then
		# Highlighted while browsing, not yet attached; Enter confirms.
		printf '#[fg=#000000,bg=#e0af68,bold] %s #[fg=#ffffff,bg=#2f3045,nobold]' "$session_name"
	elif [[ "$session_name" == "$current_session" ]]; then
		printf '#[fg=#1a1b26,bg=#bb9af7,bold] %s #[fg=#ffffff,bg=#2f3045,nobold]' "$session_name"
	else
		printf '#[fg=#ffffff,bg=#111111] %s #[fg=#ffffff,bg=#2f3045,nobold]' "$session_name"
	fi
	separator=' '
done < <(printf '%s\n' "$session_rows" | LC_ALL=C sort -t $'\t' -k1,1nr -k2,2)

printf '#[fg=#ffffff,bg=#2f3045,nobold]'
