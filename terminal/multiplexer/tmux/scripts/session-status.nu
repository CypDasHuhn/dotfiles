#!/usr/bin/env nu

def main [current_session?: string] {
	let current = if ($current_session == null or ($current_session | is-empty)) {
		^tmux display-message -p '#S' | str trim
	} else {
		$current_session
	}

	let pending = (do { ^tmux show-option -gqv "@session_pending" } | complete | get stdout | str trim)

	let rows = (
		^tmux list-sessions -F "#{session_last_attached}\t#{session_name}"
		| lines
		| filter { |l| $l | is-not-empty }
		| each { |line|
			let parts = $line | split row "\t"
			{ ts: ($parts | get 0), name: ($parts | get 1) }
		}
		| sort-by ts --reverse
		| get name
	)

	let out = ($rows | reduce --fold "" { |name, acc|
		let sep = if $acc == "" { "" } else { " " }
		let styled = if ($pending | is-not-empty) and $name == $pending and $name != $current {
			$"#[fg=#000000,bg=#e0af68,bold] ($name) #[fg=#ffffff,bg=#2f3045,nobold]"
		} else if $name == $current {
			$"#[fg=#1a1b26,bg=#bb9af7,bold] ($name) #[fg=#ffffff,bg=#2f3045,nobold]"
		} else {
			$"#[fg=#ffffff,bg=#111111] ($name) #[fg=#ffffff,bg=#2f3045,nobold]"
		}
		$acc + $sep + $styled
	})

	print -n $"($out)#[fg=#ffffff,bg=#2f3045,nobold]"
}
