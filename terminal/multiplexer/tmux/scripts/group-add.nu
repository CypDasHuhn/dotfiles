#!/usr/bin/env nu

# fzf picker that assigns existing sessions (many at once) as members of a
# group. The target group is $1; with no argument it falls back to the
# current @group-view, or asks which group to target when viewing All.
#
# Runs the picker through fzf-tmux (called from a plain run-shell binding,
# like tmux-sessionx does) rather than tmux display-popup: fzf cannot get a
# usable controlling terminal when it is a display-popup -E command, and the
# popup dies before fzf can draw.

def opt [name: string] {
	do { ^tmux show-option -gqv $name } | complete | get stdout | str trim
}

def members [group: string] {
	let val = opt $"@group:($group)"
	if $val == "" { [] } else { $val | split row "," | where { |s| $s != "" } }
}

def notify [msg: string] {
	^tmux display-message $msg
}

def pick [items: list<string>, prompt: string, multi: bool] {
	if ($items | is-empty) { return [] }
	let input = ($items | str join "\n")
	if $multi {
		($input | ^fzf-tmux -p "70%,60%" --multi --prompt $prompt | lines)
	} else {
		($input | ^fzf-tmux -p "70%,60%" --prompt $prompt | lines)
	}
}

def main [group?: string] {
	let all = (^tmux list-sessions -F "#S" | lines | where { |s| $s != "" })
	let groups = (opt "@groups" | split row "," | where { |g| $g != "" })

	let target = if ($group != null and ($group | str trim) != "") {
		$group | str trim
	} else {
		let view = (opt "@group-view")
		if ($view | is-empty) or $view == "All" {
			if ($groups | is-empty) {
				notify "no groups exist; create one with Ctrl+Shift+Alt+n first"
				return
			}
			let picked = (pick $groups "group> " false)
			if ($picked | is-empty) { return }
			$picked | first
		} else {
			$view
		}
	}

	let existing = (members $target)
	let candidates = ($all | where { |s| $s not-in $existing })

	if ($candidates | is-empty) {
		notify $"every session is already in '($target)'"
		return
	}

	let chosen = (pick $candidates "add (multi)> " true)
	if ($chosen | is-empty) { return }

	let updated = ($existing ++ $chosen | uniq)
	^tmux set-option -g $"@group:($target)" ($updated | str join ",")
	^tmux refresh-client -S
}
