#!/usr/bin/env nu

# Background helper for session-select.nu arm_timeout.
# Called via `tmux run-shell -b`; sleeps 1s then cancels the pending session
# browse if the token still matches (i.e. no newer browse action fired).

def main [token: string, client_name: string] {
	sleep 1sec
	let current = (do { ^tmux show-option -gqv "@session_pending_token" } | complete | get stdout | str trim)
	if $current == $token {
		^tmux set-option -gu "@session_pending"
		^tmux set-option -gu "@session_pending_token"
		if ($client_name | is-not-empty) {
			^tmux switch-client -c $client_name -T root
			^tmux refresh-client -t $client_name -S
		} else {
			^tmux switch-client -T root
			^tmux refresh-client -S
		}
	}
}
