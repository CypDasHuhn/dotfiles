#!/usr/bin/env nu

def --wrapped tmux-result [...args: string] {
	do { ^tmux ...$args } | complete
}

def --wrapped tmux-value [...args: string] {
	let result = (tmux-result ...$args)
	if $result.exit_code != 0 {
		return ""
	}
	$result.stdout | str trim
}

def global-option [name: string] {
	tmux-value show-option -gqv $name
}

def session-option [session: string, name: string] {
	tmux-value show-option -t $session -qv $name
}

def client-key [client: string] {
	$client
	| str replace -a "/" "_"
	| str replace -a ":" "_"
	| str replace -a "." "_"
	| str replace -a "-" "_"
}

def pending-option [kind: string, client: string] {
	$"@workspace-($kind)-pending-(client-key $client)"
}

def state-file [] {
	let home = ($env.HOME? | default ($env.USERPROFILE? | default ""))
	let base = ($env.XDG_STATE_HOME? | default ($home | path join ".local" "state"))
	$base | path join "tmux" "workspaces.json"
}

def load-state [] {
	let path = (state-file)
	if not ($path | path exists) {
		return { version: 2, workspaces: [] }
	}
	try {
		let parsed = (open --raw $path | from json)
		if (($parsed.version? | default 0) != 2) {
			return { version: 2, workspaces: [] }
		}
		{ version: 2, workspaces: ($parsed.workspaces? | default []) }
	} catch {
		{ version: 2, workspaces: [] }
	}
}

def state-related [state, id: string] {
	let records = ($state.workspaces? | default [] | where { |item| $item.id? == $id })
	if ($records | is-empty) {
		[]
	} else {
		($records | first).related? | default []
	}
}

def session-records [] {
	let result = (tmux-result list-sessions -F "#{session_name}\t#{@workspace-id}\t#{@workspace-root}\t#{@workspace-last-used}")
	if $result.exit_code != 0 {
		return []
	}
	$result.stdout
	| lines
	| where { |line| $line != "" }
	| each { |line|
		let parts = ($line | split row "\t")
		{
			name: ($parts | get -o 0 | default ""),
			id: ($parts | get -o 1 | default ""),
			root: ($parts | get -o 2 | default ""),
			mru: (try { ($parts | get -o 3 | default "0") | into int } catch { 0 })
		}
	}
}

def related-records [current: string] {
	let id = (session-option $current "@workspace-id")
	if ($id | is-empty) {
		return []
	}
	let related = (state-related (load-state) $id)
	session-records
	| where { |item| $item.id in $related }
	| sort-by mru --reverse
}

def configured-purposes [] {
	let raw = (global-option "@workspace-purposes")
	let purposes = ($raw | split row "," | each { |item| $item | str trim } | where { |item| $item != "" })
	if ($purposes | is-empty) { ["shell", "editor", "ai"] } else { $purposes }
}

def window-records [session: string] {
	let result = (tmux-result list-windows -t $"=($session)" -F "#{window_id}\t#{window_index}\t#{window_name}\t#{@workspace-purpose}")
	if $result.exit_code != 0 {
		return []
	}
	$result.stdout
	| lines
	| where { |line| $line != "" }
	| each { |line|
		let parts = ($line | split row "\t")
		{
			id: ($parts | get -o 0 | default ""),
			index: (try { ($parts | get -o 1 | default "0") | into int } catch { 0 }),
			name: ($parts | get -o 2 | default ""),
			purpose: ($parts | get -o 3 | default "")
		}
	}
}

def default-purpose [] {
	let purposes = (configured-purposes)
	let configured = (global-option "@workspace-default-purpose")
	if ($configured | is-not-empty) and ($configured in $purposes) { $configured } else { $purposes | first }
}

def status-style [style: string, text: string] {
	"#[" + $style + "]" + $text + "#[fg=#ffffff,bg=#2f3045,nobold]"
}

def status-sessions [current: string, client: string] {
	let pending = (global-option (pending-option "session" $client))
	let rows = (session-records | sort-by mru --reverse)
	let output = ($rows | reduce --fold "" { |row, acc|
		let separator = if ($acc | is-empty) { "" } else { " " }
		let style = if $row.name == $pending and $row.name != $current {
			"fg=#000000,bg=#e0af68,bold"
		} else if $row.name == $current {
			"fg=#1a1b26,bg=#bb9af7,bold"
		} else {
			"fg=#ffffff,bg=#111111"
		}
		$acc + $separator + (status-style $style (" " + $row.name + " "))
	})
	print -n ($output + "#[fg=#ffffff,bg=#2f3045,nobold]")
}

def status-related [current: string, client: string] {
	let pending = (global-option (pending-option "related" $client))
	let rows = (related-records $current)
	if ($rows | is-empty) {
		print -n (status-style "fg=#a7a7c4,bg=#2f3045" " related: none ")
		return
	}
	let output = ($rows | reduce --fold "" { |row, acc|
		let separator = if ($acc | is-empty) { "" } else { " " }
		let style = if $row.name == $pending { "fg=#000000,bg=#e0af68,bold" } else { "fg=#ffffff,bg=#111111" }
		$acc + $separator + (status-style $style (" " + $row.name + " "))
	})
	print -n ($output + "#[fg=#ffffff,bg=#2f3045,nobold]")
}

def status-purposes [session: string, current_window: string] {
	let rows = (window-records $session | sort-by index)
	let active_row = ($rows | where { |row| $row.id == $current_window } | get -o 0 | default null)
	let active = if $active_row == null or ($active_row.purpose | is-empty) { default-purpose } else { $active_row.purpose }
	let sections = (configured-purposes | each { |purpose|
		let header_style = if $purpose == $active { "fg=#1a1b26,bg=#68D57A,bold" } else { "fg=#707080,bg=#08080d,bold" }
		let header = (status-style $header_style (" " + ($purpose | str upcase) + " "))
		let tabs = ($rows | where { |row| (if ($row.purpose | is-empty) { default-purpose } else { $row.purpose }) == $purpose } | reduce --fold "" { |row, acc|
			let separator = if ($acc | is-empty) { "" } else { " " }
			let style = if $row.id == $current_window { "fg=#1a1b26,bg=#5cb2ed,bold" } else { "fg=#ffffff,bg=#111111" }
			let label = if ($row.name | is-empty) { ($row.index | into string) } else { $row.name }
			$acc + $separator + (status-style $style (" " + $label + " "))
		})
		$header + $tabs
	})
	print -n (($sections | str join "  ") + "#[fg=#ffffff,bg=#2f3045,nobold]")
}

def main [...args: string] {
	let action = ($args | get -o 0 | default "")
	let first = ($args | get -o 1 | default "")
	let second = ($args | get -o 2 | default "")
	match $action {
		"sessions" => { status-sessions $first $second }
		"related" => { status-related $first $second }
		"purposes" => { status-purposes $first $second }
		_ => { exit 2 }
	}
}
