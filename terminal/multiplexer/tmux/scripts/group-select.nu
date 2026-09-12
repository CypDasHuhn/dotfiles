#!/usr/bin/env nu

def opt [name: string] {
	do { ^tmux show-option -gqv $name } | complete | get stdout | str trim
}

def clear_selection [client_name: string] {
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

def arm_timeout [token: string, client_name: string] {
	^tmux set-option -g "@group_pending_token" $token
	^tmux run-shell -b $"nu ~/.config/tmux/scripts/group-timeout.nu '($token)' '($client_name)'"
}

def groups_plus_all [] {
	["All"] ++ (opt "@groups" | split row "," | filter { |g| $g != "" })
}

def mru_member [members: list<string>] {
	if ($members | is-empty) { return "" }
	let candidates = (^tmux list-sessions -F "#{session_last_attached}\t#{session_name}"
		| lines
		| where { |l| $l != "" }
		| each { |l|
			let parts = ($l | split row "\t")
			{ ts: ($parts | get 0), name: ($parts | get 1) }
		}
		| where { |s| $s.name in $members }
		| sort-by ts --reverse
		| get name)
	if ($candidates | is-empty) { "" } else { $candidates | first }
}

def attach_mru [members: list<string>] {
	let latest = (mru_member $members)
	if ($latest | is-not-empty) {
		^tmux switch-client -t $"=($latest)"
	}
}

def update_view [value: string, client_name: string] {
	^tmux set-option -g "@group-view" (if $value == "All" { "" } else { $value })
	clear_selection $client_name
}

def main [action: string, ...rest: string] {
	let current_session = if $action == "new" or $action == "rename" {
		$rest | get -i 1 | default ""
	} else {
		$rest | get -i 0 | default ""
	}

	let client_name = if $action == "new" or $action == "rename" {
		$rest | get -i 2 | default ""
	} else {
		$rest | get -i 1 | default ""
	}

	let arg1 = if $action == "new" or $action == "rename" {
		$rest | get -i 0 | default ""
	} else {
		""
	}

	let current = if ($current_session | is-empty) {
		^tmux display-message -p '#S' | str trim
	} else {
		$current_session
	}

	let view_raw = (opt "@group-view")
	let view = if ($view_raw | is-empty) { "All" } else { $view_raw }

	match $action {
		"left" | "right" => {
			let list = (groups_plus_all)
			let count = $list | length
			if $count < 2 { return }

			let pending_raw = (opt "@group_pending")
			let pending = if ($pending_raw | is-empty) { $view } else { $pending_raw }
			let matching = ($list | enumerate | where { |g| $g.item == $pending })
			let index = if ($matching | is-empty) { 0 } else { $matching | first | get index }

			let target = if $action == "right" {
				($index + 1) mod $count
			} else {
				($index - 1 + $count) mod $count
			}

			^tmux set-option -g "@group_pending" ($list | get $target)
			^tmux switch-client -T group-select
			^tmux refresh-client -S

			let token = (date now | into int | into string)
			arm_timeout $token $client_name
		}
		"confirm" => {
			let target = (opt "@group_pending")
			let target = if ($target | is-empty) { $view } else { $target }
			if $target != "All" {
				let members = (opt $"@group:($target)" | split row "," | where { |s| $s != "" })
				attach_mru $members
			}
			update_view $target $client_name
		}
		"cancel" => {
			clear_selection $client_name
		}
		"new" => {
			let name = ($arg1 | str trim)
			if ($name | is-empty) {
				^tmux display-message "group name was empty"
				exit 2
			}
			let existing = (opt "@groups" | split row "," | filter { |g| $g == $name })
			if ($existing | is-not-empty) {
				^tmux display-message $"group '($name)' already exists"
				exit 1
			}
			let old = (opt "@groups")
			let list = if ($old | is-empty) { $name } else { $"($old),($name)" }
			^tmux set-option -g "@groups" $list
			^tmux set-option -g $"@group:($name)" $current
			^tmux set-option -g "@group-view" $name
			clear_selection $client_name
		}
		"remove" => {
			let target = (opt "@group_pending")
			let target = if ($target | is-empty) { $view } else { $target }
			if $target == "All" or ($target | is-empty) {
				^tmux display-message "no group highlighted"
				exit 1
			}
			let kept = (opt $"@group:($target)" | split row "," | filter { |s| $s != "" and $s != $current })
			^tmux set-option -g $"@group:($target)" ($kept | str join ",")
			if $view == $target {
				attach_mru $kept
			}
			clear_selection $client_name
		}
		"rename" => {
			let new_name = ($arg1 | str trim)
			let old_name = (opt "@group_pending")
			let old_name = if ($old_name | is-empty) { $view } else { $old_name }
			if ($new_name | is-empty) or $old_name == "All" { exit 2 }
			let old_members = (opt $"@group:($old_name)")
			^tmux set-option -gu $"@group:($old_name)"
			^tmux set-option -g $"@group:($new_name)" $old_members
			^tmux set-option -g "@groups" (opt "@groups" | split row "," | each { |g| if $g == $old_name { $new_name } else { $g } } | str join ",")
			if $view == $old_name { ^tmux set-option -g "@group-view" $new_name }
			^tmux set-option -gu "@group_pending"
			clear_selection $client_name
		}
		"delete" => {
			let target = (opt "@group_pending")
			let target = if ($target | is-empty) { $view } else { $target }
			if $target == "All" or ($target | is-empty) {
				^tmux display-message "cannot delete All"
				exit 1
			}
			^tmux set-option -gu $"@group:($target)"
			^tmux set-option -g "@groups" (opt "@groups" | split row "," | filter { |g| $g != "" and $g != $target } | str join ",")
			if $view == $target { ^tmux set-option -g "@group-view" "" }
			clear_selection $client_name
		}
		_ => {
			print -e $"usage: group-select.nu left|right|confirm|cancel|new|remove|rename|delete [args...]"
			exit 2
		}
	}
}
