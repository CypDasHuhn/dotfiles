#!/usr/bin/env nu

def opt [name: string] {
	do { ^tmux show-option -gqv $name } | complete | get stdout | str trim
}

def members [group: string] {
	let val = opt $"@group:($group)"
	if $val == "" { [] } else { $val | split row "," | where { |s| $s != "" } }
}

def name_count [name: string, count: string] {
	$name + " (" + $count + ")"
}

def wrap [style: string, text: string] {
		"#[" + $style + "] " + $text + " #[fg=#ffffff,bg=#2f3045,nobold]"
}

def main [] {
	let view = (opt "@group-view")
	let view = if ($view | is-empty) { "All" } else { $view }
	let pending = (opt "@group_pending")
	let groups = (opt "@groups" | split row "," | where { |g| $g != "" })

	let all_count = (^tmux list-sessions -F "#S" | lines | where { |l| $l != "" } | length | into string)
	let all_chip = if ($pending == "All" and $view != "All") {
		wrap "fg=#000000,bg=#e0af68,bold" (name_count "All" $all_count)
	} else if $view == "All" {
		wrap "fg=#1a1b26,bg=#68D57A,bold" (name_count "All" $all_count)
	} else {
		wrap "fg=#ffffff,bg=#111111" (name_count "All" $all_count)
	}

	let out = ([$all_chip]
		| append ($groups | each { |g|
			let count = (members $g | length | into string)
			if $g == $pending and $g != $view {
				wrap "fg=#000000,bg=#e0af68,bold" (name_count $g $count)
			} else if $g == $view {
				wrap "fg=#1a1b26,bg=#68D57A,bold" (name_count $g $count)
			} else {
				wrap "fg=#ffffff,bg=#111111" (name_count $g $count)
			}
		})
		| append ("#[fg=#a7a7c4,bg=#111111] + #[fg=#ffffff,bg=#2f3045,nobold]")
		| str join " ")

	print -n ($out + "#[fg=#ffffff,bg=#2f3045,nobold]")
}
