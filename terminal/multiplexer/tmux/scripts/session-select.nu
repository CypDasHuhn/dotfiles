#!/usr/bin/env nu

# Session selection without immediately attaching. Shift+Alt+h/l moves a
# "pending" highlight through the recency-ordered session list; since
# browsing no longer calls switch-client, session_last_attached timestamps
# don't change mid-browse, so the order stays stable instead of collapsing
# into a two-session toggle. Enter attaches to the pending session; Escape
# cancels and returns to the actually attached one.

def arm_timeout [token: string, client_name: string] {
	^tmux set-option -g "@session_pending_token" $token
	^tmux run-shell -b $"nu ~/.config/tmux/scripts/session-timeout.nu '($token)' '($client_name)'"
}

def clear_selection [client_name: string] {
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

def get_sessions [] {
	^tmux list-sessions -F "#{session_last_attached}\t#{session_name}"
	| lines
	| filter { |l| $l | is-not-empty }
	| each { |line|
		let parts = $line | split row "\t"
		{ ts: ($parts | get 0), name: ($parts | get 1) }
	}
	| sort-by ts --reverse
	| get name
}

def main [
	action: string,
	...rest: string
] {
	let current_session = if $action == "rename" {
		$rest | get -i 1 | default ""
	} else {
		$rest | get -i 0 | default ""
	}

	let client_name = if $action == "rename" {
		$rest | get -i 2 | default ""
	} else {
		$rest | get -i 1 | default ""
	}

	let new_name = if $action == "rename" {
		$rest | get -i 0 | default ""
	} else {
		""
	}

	let current = if ($current_session | is-empty) {
		^tmux display-message -p '#S' | str trim
	} else {
		$current_session
	}

	let pending_raw = (do { ^tmux show-option -gqv "@session_pending" } | complete | get stdout | str trim)

	let has_pending = if ($pending_raw | is-not-empty) {
		(do { ^tmux has-session -t $"=($pending_raw)" } | complete | get exit_code) == 0
	} else {
		false
	}

	let pending = if ($pending_raw | is-empty) or (not $has_pending) {
		$current
	} else {
		$pending_raw
	}

	match $action {
		"confirm" => {
			if ($pending | is-not-empty) {
				^tmux switch-client -t $"=($pending)"
			}
			clear_selection $client_name
		}
		"cancel" => {
			clear_selection $client_name
		}
		"kill" => {
			^tmux kill-session -t $"=($pending)"
			clear_selection $client_name
		}
		"rename" => {
			if ($new_name | is-empty) { exit 2 }
			^tmux rename-session -t $"=($pending)" $new_name
			clear_selection $client_name
		}
		"left" | "right" => {
			let sessions = get_sessions
			let count = $sessions | length
			if $count < 2 { return }

			let matching = ($sessions | enumerate | where { |s| $s.item == $pending })
			let pending_index = if ($matching | is-empty) { 0 } else { $matching | first | get index }

			let target_index = if $action == "right" {
				($pending_index + 1) mod $count
			} else {
				($pending_index - 1 + $count) mod $count
			}

			^tmux set-option -g "@session_pending" ($sessions | get $target_index)
			^tmux switch-client -T session-select
			^tmux refresh-client -S

			let token = (date now | into int | into string)
			arm_timeout $token $client_name
		}
		_ => {
			print -e $"usage: session-select.nu left|right|confirm|cancel|kill|rename [args...]"
			exit 2
		}
	}
}
