#!/usr/bin/env bash

# Session selection without immediately attaching. Shift+Alt+h/l moves a
# "pending" highlight through the recency-ordered session list; since
# browsing no longer calls switch-client, session_last_attached timestamps
# don't change mid-browse, so the order stays stable instead of collapsing
# into a two-session toggle. Enter attaches to the pending session; Escape
# cancels and returns to the actually attached one.

set -euo pipefail

action=${1:-}
case "$action" in
	left|right|confirm|cancel|kill|rename)
		;;
	*)
		printf 'usage: %s left|right|confirm|cancel|kill|rename [client_session] [client_name]\n' "$0" >&2
		exit 2
		;;
esac

if [[ "$action" == "rename" ]]; then
	new_name=${2:-}
	current_session=${3:-}
	client_name=${4:-}
else
	current_session=${2:-}
	client_name=${3:-}
fi

if [[ -z "$current_session" ]]; then
	current_session=$(tmux display-message -p '#S')
fi

pending_session=$(tmux show-option -gqv @session_pending 2>/dev/null || true)
if [[ -z "$pending_session" ]] || ! tmux has-session -t "=$pending_session" 2>/dev/null; then
	pending_session="$current_session"
fi

clear_selection() {
	tmux set-option -gu @session_pending
	tmux set-option -gu @session_pending_token
	if [[ -n "$client_name" ]]; then
		tmux switch-client -c "$client_name" -T root
		tmux refresh-client -t "$client_name" -S
	else
		tmux switch-client -T root
		tmux refresh-client -S
	fi
}

arm_timeout() {
	local token
	token=$(date +%s%N)
	tmux set-option -g @session_pending_token "$token"

	local quoted_client
	printf -v quoted_client '%q' "$client_name"
	tmux run-shell -b "sleep 1; if [ \"\$(tmux show-option -gqv @session_pending_token)\" = \"$token\" ]; then tmux set-option -gu @session_pending && tmux set-option -gu @session_pending_token && tmux switch-client -c $quoted_client -T root && tmux refresh-client -t $quoted_client -S; fi"
}

case "$action" in
	confirm)
		if [[ -n "$pending_session" ]]; then
			tmux switch-client -t "=${pending_session}"
		fi
		clear_selection
		exit 0
		;;
	cancel)
		clear_selection
		exit 0
		;;
	kill)
		tmux kill-session -t "=${pending_session}"
		clear_selection
		exit 0
		;;
		rename)
			if [[ -z "$new_name" ]]; then
				exit 2
		fi
		tmux rename-session -t "=${pending_session}" "$new_name"
		clear_selection
		exit 0
		;;
esac

session_format=$'#{session_last_attached}\t#{session_name}'
session_rows=$(tmux list-sessions -F "$session_format")

sessions=()
while IFS= read -r session_name; do
	if [[ -n "$session_name" ]]; then
		sessions+=("$session_name")
	fi
done < <(printf '%s\n' "$session_rows" | LC_ALL=C sort -t $'\t' -k1,1nr -k2,2 | cut -f2-)

session_count=${#sessions[@]}
if (( session_count < 2 )); then
	exit 0
fi

pending_index=-1
for index in "${!sessions[@]}"; do
	if [[ "${sessions[$index]}" == "$pending_session" ]]; then
		pending_index=$index
		break
	fi
done

if (( pending_index < 0 )); then
	pending_index=0
fi

if [[ "$action" == 'right' ]]; then
	target_index=$(( (pending_index + 1) % session_count ))
else
	target_index=$(( (pending_index - 1 + session_count) % session_count ))
fi

tmux set-option -g @session_pending "${sessions[$target_index]}"
tmux switch-client -T session-select
tmux refresh-client -S
arm_timeout
