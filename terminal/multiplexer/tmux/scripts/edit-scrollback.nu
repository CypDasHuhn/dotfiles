#!/usr/bin/env nu

def main [pane_id?: string] {
	let pane = if ($pane_id == null or ($pane_id | is-empty)) {
		^tmux display-message -p '#{pane_id}' | str trim
	} else {
		$pane_id
	}

	let editor = $env.EDITOR? | default "nvim"
	let tmp_base = $env.TMPDIR? | default ($env.TEMP? | default "/tmp")
	let tmp = $"($tmp_base)/tmux-scrollback-(random int 100000..999999).txt"

	^tmux capture-pane -p -t $pane -S - -E - | save --force $tmp
	^tmux new-window -n "scrollback" $"($editor) ($tmp)"
}
