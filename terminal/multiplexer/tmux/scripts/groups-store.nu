#!/usr/bin/env nu

# Persists the session-group tmux options (@groups and @group:<name>) to a
# state file so they survive a tmux server restart / resurrect, which does
# not save user options on its own. `save` is called after every group
# mutation; `load` runs when the tmux config is sourced.

def opt [name: string] {
	do { ^tmux show-option -gqv $name } | complete | get stdout | str trim
}

def state-file [] {
	let home = ($env.HOME? | default ($env.USERPROFILE? | default ""))
	let base = ($env.XDG_STATE_HOME? | default ($home | path join ".local" "state"))
	let dir = ($base | path join "tmux")
	mkdir $dir
	$dir | path join "groups"
}

def groups [] {
	opt "@groups" | split row "," | where { |g| $g != "" }
}

def persist [path: string] {
	let tab = (char tab)
	let header = "@groups" + $tab + (opt "@groups")
	let rows = (groups | each { |g| "@group:" + $g + $tab + (opt $"@group:($g)") })
	([$header] ++ $rows | str join "\n") | save -f $path
}

def restore [path: string] {
	if not ($path | path exists) { return }
	let tab = (char tab)
	for g in (groups) {
		^tmux set-option -gu $"@group:($g)"
	}
	^tmux set-option -gu "@groups"
	for line in (open --raw $path | lines | where { |l| ($l | str trim) != "" }) {
		let parts = ($line | split row $tab)
		let key = ($parts | get 0)
		let value = ($parts | skip 1 | str join $tab)
		^tmux set-option -g $key $value
	}
}

def main [action: string] {
	let path = (state-file)
	match $action {
		"save" => { persist $path }
		"load" => { restore $path }
		_ => {
			print -e "usage: groups-store.nu save|load"
			exit 2
		}
	}
}
