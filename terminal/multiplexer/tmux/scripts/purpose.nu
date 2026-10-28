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

def session-option [session: string, name: string] {
	tmux-value show-option -t $session -qv $name
}

def set-session-option [session: string, name: string, value: string] {
	^tmux set-option -t $session $name $value
}

def set-window-option [window: string, name: string, value: string] {
	^tmux set-window-option -t $window $name $value
}

def window-records [session: string] {
	let result = (tmux-result list-windows -t $"=($session)" -F "#{window_id}\t#{window_index}\t#{window_name}\t#{@workspace-purpose}\t#{@workspace-last-used}")
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
			purpose: ($parts | get -o 3 | default "shell"),
			last: (try { ($parts | get -o 4 | default "0") | into int } catch { 0 })
		}
	}
}

def record-use [session: string, window: string, purpose: string] {
	let timestamp = (date now | into int | into string)
	let args = [
		"set-option", "-t", $session, "@workspace-active-purpose", $purpose,
		";",
		"set-window-option", "-t", $window, "@workspace-last-used", $timestamp
	]
	tmux-result ...$args | ignore
}

def select-with-use [session: string, window: string, purpose: string] {
	let timestamp = (date now | into int | into string)
	let args = [
		"set-option", "-t", $session, "@workspace-active-purpose", $purpose,
		";",
		"set-window-option", "-t", $window, "@workspace-last-used", $timestamp,
		";",
		"select-window", "-t", $window
	]
	tmux-result ...$args | ignore
}

def create-window [session: string, purpose: string] {
	let root = (session-option $session "@workspace-root")
	if ($root | is-empty) {
		^tmux display-message "workspace has no directory anchor"
		return
	}
	set-session-option $session "@workspace-new-purpose" $purpose
	let result = (tmux-result new-window -t $"=($session)" -c $root -P -F "#{window_id}")
	if $result.exit_code != 0 {
		set-session-option $session "@workspace-new-purpose" ""
		return
	}
	let window = ($result.stdout | str trim)
	set-window-option $window "@workspace-purpose" $purpose
	record-use $session $window $purpose
}

def select-purpose [purpose: string, session: string] {
	let windows = (window-records $session | where { |window| $window.purpose == $purpose } | sort-by last --reverse)
	let target = ($windows | get -o 0 | default null)
	if $target == null {
		create-window $session $purpose
		return
	}
	select-with-use $session $target.id $target.purpose
}

def current-window [client: string] {
	if ($client | is-empty) {
		tmux-value display-message -p "#{window_id}"
	} else {
		tmux-value display-message -p -t $client "#{window_id}"
	}
}

def cycle-purpose [direction: string, session: string, client: string] {
	let current = (current-window $client)
	let rows = (window-records $session)
	let current_row = ($rows | where { |row| $row.id == $current } | get -o 0 | default null)
	let purpose = if $current_row == null or ($current_row.purpose | is-empty) { "shell" } else { $current_row.purpose }
	let windows = ($rows | where { |window| $window.purpose == $purpose } | sort-by index)
	let count = ($windows | length)
	if $count < 2 {
		return
	}
	let matching = ($windows | enumerate | where { |item| $item.item.id == $current })
	let index = if ($matching | is-empty) { 0 } else { $matching | first | get index }
	let target_index = if $direction == "right" {
		($index + 1) mod $count
	} else {
		($index - 1 + $count) mod $count
	}
	let target = ($windows | get $target_index)
	select-with-use $session $target.id $target.purpose
}

def main [...args: string] {
	let action = ($args | get -o 0 | default "")
	let first = ($args | get -o 1 | default "")
	let second = ($args | get -o 2 | default "")
	let third = ($args | get -o 3 | default "")
	match $action {
		"select" => { select-purpose $first $second }
		"cycle" => { cycle-purpose $first $second $third }
		_ => { exit 2 }
	}
}
