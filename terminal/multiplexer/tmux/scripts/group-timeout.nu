#!/usr/bin/env nu

def main [token: string, client_name: string] {
	sleep 1sec
	let current = (do { ^tmux show-option -gqv "@group_pending_token" } | complete | get stdout | str trim)
	if $current == $token {
		^tmux set-option -gu "@group_pending"
		^tmux set-option -gu "@group_pending_token"
		if ($client_name | is-not-empty) {
			^tmux switch-client -c $client_name -T root
			^tmux refresh-client -t $client_name -S
		} else {
			^tmux switch-client -T root
			^tmux refresh-client -S
		}
	}
}
