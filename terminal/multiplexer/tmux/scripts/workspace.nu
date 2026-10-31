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

def is-windows [] {
	(($env.WINDIR? | default "") | is-not-empty)
}

def global-option [name: string] {
	tmux-value show-option -gqv $name
}

def session-option [session: string, name: string] {
	tmux-value show-option -t $session -qv $name
}

def window-option [window: string, name: string] {
	let result = (tmux-result show-window-option -t $window -v $name)
	if $result.exit_code != 0 {
		return ""
	}
	$result.stdout | str trim
}

def set-session-option [session: string, name: string, value: string] {
	^tmux set-option -t $session $name $value
}

def set-window-option [window: string, name: string, value: string] {
	^tmux set-window-option -t $window $name $value
}

def client-key [client: string] {
	$client
	| str replace -a "/" "_"
	| str replace -a ":" "_"
	| str replace -a "." "_"
	| str replace -a "-" "_"
}

def pending-option [kind: string, client: string, field: string] {
	$"@workspace-($kind)-($field)-(client-key $client)"
}

def current-client [client?: string] {
	if ($client != null and ($client | is-not-empty)) {
		return $client
	}

	let pane = ($env.TMUX_PANE? | default "")
	if ($pane | is-not-empty) {
		return (tmux-value display-message -p -t $pane "#{client_name}")
	}

	""
}

def session-for [client?: string] {
	let selected_client = (current-client $client)
	if ($selected_client | is-not-empty) {
		return (tmux-value display-message -p -t $selected_client "#{client_session}")
	}

	tmux-value display-message -p "#S"
}

def normalize-root [value: string] {
	let expanded = ($value | path expand)
	let candidate = if (($expanded | path exists) and (($expanded | path type) == "file")) {
		$expanded | path dirname
	} else {
		$expanded
	}

	let resolved = if (is-windows) {
		$candidate
	} else {
		let result = (do { ^realpath $candidate } | complete)
		if $result.exit_code == 0 {
			$result.stdout | str trim
		} else {
			$candidate
		}
	}

	let normalized = ($resolved | path expand | str replace -a "\\" "/")
	if (is-windows) {
		$normalized | str downcase
	} else {
		$normalized
	}
}

def state-file [] {
	let home = ($env.HOME? | default ($env.USERPROFILE? | default ""))
	let base = ($env.XDG_STATE_HOME? | default ($home | path join ".local" "state"))
	let dir = ($base | path join "tmux")
	mkdir $dir
	$dir | path join "workspaces.json"
}

def empty-state [] {
	{ version: 2, workspaces: [] }
}

def load-state [] {
	let path = (state-file)
	if not ($path | path exists) {
		return (empty-state)
	}

	try {
		let parsed = (open --raw $path | from json)
		if (($parsed.version? | default 0) != 2) {
			return (empty-state)
		}
		{ version: 2, workspaces: ($parsed.workspaces? | default []) }
	} catch {
		empty-state
	}
}

def save-state [state] {
	let path = (state-file)
	$state | to json | save -f $path
}

def state-workspaces [state] {
	$state.workspaces?
	| default []
	| each { |item|
		{
			id: ($item.id? | default ""),
			name: ($item.name? | default ""),
			root: ($item.root? | default ""),
			related: ($item.related? | default []),
			excluded: ($item.excluded? | default []),
			last_used: ($item.last_used? | default "0")
		}
	}
	| where { |item| ($item.id | is-not-empty) and ($item.root | is-not-empty) }
}

def persisted-workspace [state, name: string, root: string] {
	state-workspaces $state
	| where { |item| $item.name == $name and $item.root == $root }
	| get -o 0
	| default null
}

def state-record [state, id: string] {
	let records = (state-workspaces $state | where { |item| $item.id == $id })
	if ($records | is-empty) {
		{ id: $id, name: "", root: "", related: [], excluded: [], last_used: "0" }
	} else {
		$records | first
	}
}

def ensure-state-workspace [state, id: string, root: string, name?: string] {
	let records = (state-workspaces $state)
	let existing = ($records | where { |item| $item.id == $id } | get -o 0 | default null)
	let workspace_name = if ($name != null and ($name | is-not-empty)) {
		$name
	} else if $existing != null {
		$existing.name
	} else {
		""
	}
	let workspaces = if $existing != null {
		$records | each { |item|
			if $item.id == $id {
				{ id: $id, name: $workspace_name, root: $root, related: $item.related, excluded: $item.excluded, last_used: $item.last_used }
			} else {
				$item
			}
		}
	} else {
		$records | append { id: $id, name: $workspace_name, root: $root, related: [], excluded: [], last_used: "0" }
	}
	{ version: 2, workspaces: $workspaces }
}

def replace-state-record [state, id: string, root: string, related: list<string>, last_used: string, excluded?: list<string>] {
	let existing = (state-record $state $id)
	let next_excluded = if ($excluded == null) { $existing.excluded } else { $excluded }
	let records = (state-workspaces $state | each { |item|
		if $item.id == $id {
			{ id: $id, name: $item.name, root: $root, related: $related, excluded: $next_excluded, last_used: $last_used }
		} else {
			$item
		}
	})
	if ($records | any { |item| $item.id == $id }) {
		{ version: 2, workspaces: $records }
	} else {
		{ version: 2, workspaces: ($records | append { id: $id, name: ($existing.name? | default ""), root: $root, related: $related, excluded: $next_excluded, last_used: $last_used }) }
	}
}

def link-workspaces [state, left_id: string, left_root: string, right_id: string, right_root: string] {
	let state = (ensure-state-workspace (ensure-state-workspace $state $left_id $left_root) $right_id $right_root)
	let left_record = (state-record $state $left_id)
	let right_record = (state-record $state $right_id)
	let left_related = ($left_record.related | append $right_id | uniq)
	let right_related = ($right_record.related | append $left_id | uniq)
	let left_excluded = ($left_record.excluded | where { |item| $item != $right_id })
	let right_excluded = ($right_record.excluded | where { |item| $item != $left_id })
	let state = (replace-state-record $state $left_id $left_root $left_related $left_record.last_used $left_excluded)
	replace-state-record $state $right_id $right_root $right_related $right_record.last_used $right_excluded
}

def unlink-workspaces [state, left_id: string, left_root: string, right_id: string, right_root: string] {
	let state = (ensure-state-workspace (ensure-state-workspace $state $left_id $left_root) $right_id $right_root)
	let left_record = (state-record $state $left_id)
	let right_record = (state-record $state $right_id)
	let left_related = ($left_record.related | where { |item| $item != $right_id })
	let right_related = ($right_record.related | where { |item| $item != $left_id })
	let state = (replace-state-record $state $left_id $left_root $left_related $left_record.last_used)
	replace-state-record $state $right_id $right_root $right_related $right_record.last_used
}

def exclude-workspace [state, id: string, root: string, target_id: string] {
	let state = (ensure-state-workspace $state $id $root)
	let record = (state-record $state $id)
	let excluded = ($record.excluded | append $target_id | uniq)
	replace-state-record $state $id $root $record.related $record.last_used $excluded
}

def configured-purposes [] {
	let configured = (global-option "@workspace-purposes")
	let purposes = ($configured | split row "," | each { |item| $item | str trim } | where { |item| $item != "" })
	if ($purposes | is-empty) {
		["shell", "editor", "ai"]
	} else {
		$purposes
	}
}

def default-purpose [] {
	let purposes = (configured-purposes)
	let configured = (global-option "@workspace-default-purpose")
	if ($configured | is-not-empty) and ($configured in $purposes) {
		$configured
	} else {
		$purposes | first
	}
}

def new-workspace-id [] {
	let timestamp = (date now | into int | into string)
	let nonce = (random int 100000..999999 | into string)
	$"ws-($timestamp)-($nonce)"
}

def ensure-workspace-id [session: string, root?: string] {
	let stored = (session-option $session "@workspace-id")
	if ($stored | is-not-empty) {
		return $stored
	}

	let normalized = if ($root != null and ($root | is-not-empty)) {
		normalize-root $root
	} else {
		session-root $session
	}
	let persisted = if ($normalized | is-not-empty) {
		persisted-workspace (load-state) $session $normalized
	} else {
		null
	}
	let id = if $persisted != null { $persisted.id } else { new-workspace-id }
	set-session-option $session "@workspace-id" $id
	$id
}

def ensure-session-last-used [session: string, id: string, state] {
	let stored = (session-option $session "@workspace-last-used")
	if ($stored | is-not-empty) {
		return $stored
	}

	let persisted = ((state-record $state $id).last_used | default "0")
	let value = if ($persisted | is-empty) { "0" } else { $persisted }
	set-session-option $session "@workspace-last-used" $value
	$value
}

def mark-session-used [session: string] {
	if ($session | is-empty) {
		return
	}
	let root = (session-root $session)
	if ($root | is-empty) {
		return
	}
	let id = (ensure-workspace-id $session $root)
	let timestamp = (date now | into int | into string)
	set-session-option $session "@workspace-last-used" $timestamp
	let state = (ensure-state-workspace (load-state) $id $root $session)
	let record = (state-record $state $id)
	save-state (replace-state-record $state $id $root $record.related $timestamp)
}

def session-root [session: string] {
	let stored = (session-option $session "@workspace-root")
	if ($stored | is-not-empty) {
		return (normalize-root $stored)
	}

	let paths = (tmux-value list-panes -t $"=($session)" -F "#{pane_current_path}" | lines | where { |item| $item != "" })
	if ($paths | is-empty) {
		""
	} else {
		normalize-root ($paths | first)
	}
}

def git-common-for-root [root: string] {
	if ($root | is-empty) {
		return ""
	}
	let result = (do { ^git -C $root rev-parse --path-format=absolute --git-common-dir } | complete)
	if $result.exit_code != 0 {
		return ""
	}
	let common = ($result.stdout | str trim)
	if ($common | is-empty) {
		""
	} else {
		normalize-root $common
	}
}

def ensure-git-common [session: string, root: string] {
	let stored = (session-option $session "@workspace-git-common")
	if ($stored | is-not-empty) {
		return (normalize-root $stored)
	}
	let common = (git-common-for-root $root)
	if ($common | is-not-empty) {
		set-session-option $session "@workspace-git-common" $common
	}
	$common
}

def set-git-common [session: string, root: string] {
	let common = (git-common-for-root $root)
	if ($common | is-empty) {
		^tmux set-option -t $session -u "@workspace-git-common"
	} else {
		set-session-option $session "@workspace-git-common" $common
	}
	$common
}

def session-records [] {
	let result = (tmux-result list-sessions -F "#{session_name}\t#{@workspace-id}\t#{@workspace-root}\t#{@workspace-last-used}\t#{@workspace-git-common}")
	if $result.exit_code != 0 {
		return []
	}

	$result.stdout
	| lines
	| where { |line| $line != "" }
	| each { |line|
		let parts = ($line | split row "\t")
		let name = ($parts | get -o 0 | default "")
		let id = ($parts | get -o 1 | default "")
		let stored = ($parts | get -o 2 | default "")
		let last_raw = ($parts | get -o 3 | default "0")
		let common_raw = ($parts | get -o 4 | default "")
		let root = if ($stored | is-empty) { session-root $name } else { normalize-root $stored }
		{
			name: $name,
			id: $id,
			root: $root,
			mru: (try { $last_raw | into int } catch { 0 }),
			git_common: (if ($common_raw | is-empty) { "" } else { normalize-root $common_raw })
		}
	}
}

def ensure-session-identities [] {
	for session in (session-records) {
		if ($session.root | is-not-empty) {
			synchronize-session-state $session.name $session.root | ignore
		}
	}
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
		let purpose_raw = ($parts | get -o 3 | default "")
		let last_raw = ($parts | get -o 4 | default "0")
		let index = (try { ($parts | get -o 1 | default "0") | into int } catch { 0 })
		let last = (try { $last_raw | into int } catch { 0 })
		{
			id: ($parts | get -o 0 | default ""),
			index: $index,
			name: ($parts | get -o 2 | default ""),
			purpose: (if ($purpose_raw | is-empty) { default-purpose } else { $purpose_raw }),
			last: $last
		}
	}
}

def ensure-window-purpose [window: string] {
	let purpose = (window-option $window "@workspace-purpose")
	if ($purpose | is-empty) {
		set-window-option $window "@workspace-purpose" (default-purpose)
	}

	let last = (window-option $window "@workspace-last-used")
	if ($last | is-empty) {
		set-window-option $window "@workspace-last-used" "0"
	}
}

def record-window-use [session: string, window: string, purpose?: string] {
	let selected = if ($purpose != null and ($purpose | is-not-empty)) {
		$purpose
	} else {
		ensure-window-purpose $window
		window-option $window "@workspace-purpose"
	}
	let timestamp = (date now | into int | into string)
	let args = [
		"set-option", "-t", $session, "@workspace-active-purpose", $selected,
		";",
		"set-window-option", "-t", $window, "@workspace-last-used", $timestamp
	]
	tmux-result ...$args | ignore
}

def synchronize-session-state [session: string, root: string] {
	let normalized = (normalize-root $root)
	let id = (ensure-workspace-id $session $normalized)
	set-session-option $session "@workspace-root" $normalized
	set-git-common $session $normalized | ignore
	let state = (ensure-state-workspace (load-state) $id $normalized $session)
	ensure-session-last-used $session $id $state | ignore
	save-state $state
	$id
}

def initialize-session [session: string, root: string] {
	let normalized = (normalize-root $root)
	synchronize-session-state $session $normalized | ignore

	for window in (window-records $session) {
		ensure-window-purpose $window.id
	}

	let selected = (tmux-value display-message -p -t $"=($session)" "#{window_id}")
	if ($selected | is-not-empty) {
		record-window-use $session $selected
	}
	$normalized
}

def current-window [client?: string] {
	let selected_client = (current-client $client)
	if ($selected_client | is-not-empty) {
		return (tmux-value display-message -p -t $selected_client "#{window_id}")
	}

	tmux-value display-message -p "#{window_id}"
}

def current-purpose [session: string, client?: string] {
	let window = (current-window $client)
	let purpose = if ($window | is-not-empty) { window-option $window "@workspace-purpose" } else { "" }
	if ($purpose | is-empty) {
		default-purpose
	} else {
		$purpose
	}
}

def session-name-for [root: string] {
	let base_raw = ($root | path basename)
	let base = if ($base_raw | is-empty) { "workspace" } else { $base_raw | str replace -ra "[^A-Za-z0-9._-]" "-" }
	mut candidate = $base
	mut suffix = 1
	mut occupied = true
	while $occupied {
		let name_to_check = $candidate
		$occupied = (session-records | any { |item| $item.name == $name_to_check })
		if not $occupied { break }
		$suffix = $suffix + 1
		$candidate = $"($base)-($suffix)"
	}
	$candidate
}

def create-session [root: string] {
	let name = (session-name-for $root)
	let result = (tmux-result new-session -d -s $name -c $root)
	if $result.exit_code != 0 {
		^tmux display-message $"could not create workspace: ($result.stderr | str trim)"
		return ""
	}

	initialize-session $name $root
	mark-session-used $name
}

def create-window [session: string, purpose: string, name?: string, command?: string] {
	let root = (session-root $session)
	if ($root | is-empty) {
		^tmux display-message "workspace has no directory anchor"
		return ""
	}

	mut args = ["new-window", "-t", $"=($session)", "-c", $root, "-P", "-F", "#{window_id}"]
	if ($name != null and ($name | is-not-empty)) {
		$args = ($args ++ ["-n", $name])
	}
	if ($command != null and ($command | is-not-empty)) {
		$args = ($args ++ [$command])
	}

	set-session-option $session "@workspace-new-purpose" $purpose
	let result = (tmux-result ...$args)
	if $result.exit_code != 0 {
		set-session-option $session "@workspace-new-purpose" ""
		^tmux display-message $"could not create tab: ($result.stderr | str trim)"
		return ""
	}

	let window = ($result.stdout | str trim)
	set-window-option $window "@workspace-purpose" $purpose
	set-window-option $window "@workspace-last-used" "0"
	record-window-use $session $window $purpose
	$window
}

def move-to-session [session: string, client?: string] {
	let selected_client = (current-client $client)
	if ($selected_client | is-not-empty) {
		^tmux switch-client -c $selected_client -t $"=($session)"
	} else {
		^tmux attach-session -t $"=($session)"
	}
}

def activate-purpose [session: string, purpose: string] {
	let windows = (window-records $session | where { |window| $window.purpose == $purpose } | sort-by last --reverse)
	let target = ($windows | get -o 0 | default null)
	if $target == null {
		create-window $session $purpose | ignore
	} else {
		record-window-use $session $target.id $target.purpose
		^tmux select-window -t $target.id
	}
}

def cycle-purpose [direction: string, client?: string] {
	let client_name = (current-client $client)
	let session = (session-for $client_name)
	if ($session | is-empty) {
		return
	}

	let purpose = (current-purpose $session $client_name)
	let windows = (window-records $session | where { |window| $window.purpose == $purpose } | sort-by index)
	let count = ($windows | length)
	if $count < 2 {
		return
	}

	let current = (current-window $client_name)
	let matching = ($windows | enumerate | where { |item| $item.item.id == $current })
	let index = if ($matching | is-empty) { 0 } else { $matching | first | get index }
	let target = if $direction == "right" {
		($index + 1) mod $count
	} else {
		($index - 1 + $count) mod $count
	}
	let window = ($windows | get $target)
	record-window-use $session $window.id $window.purpose
	^tmux select-window -t $window.id
}

def new-window-for-client [client?: string] {
	let client_name = (current-client $client)
	let session = (session-for $client_name)
	if ($session | is-empty) {
		return
	}
	let purpose = (current-purpose $session $client_name)
	create-window $session $purpose | ignore
}

def new-command-window [name: string, client: string, command: string] {
	let client_name = (current-client $client)
	let session = (session-for $client_name)
	if ($session | is-empty) {
		return
	}
	let purpose = (current-purpose $session $client_name)
	create-window $session $purpose $name $command | ignore
}

def open-workspace [raw_path?: string, purpose?: string] {
	let client_name = (current-client)
	let requested = if ($raw_path != null and ($raw_path | is-not-empty)) {
		$raw_path
	} else if ($client_name | is-not-empty) {
		tmux-value display-message -p -t $client_name "#{pane_current_path}"
	} else {
		$env.PWD
	}

	let root = (normalize-root $requested)
	if not ($root | path exists) {
		^tmux display-message $"directory does not exist: ($root)"
		return
	}

	let existing = (session-records | where { |item| $item.root == $root } | get -o 0 | default null)
	let session = if $existing == null {
		create-session $root
	} else {
		initialize-session $existing.name $root
		$existing.name
	}

	if ($session | is-empty) {
		return
	}
	if ($purpose != null and ($purpose | is-not-empty)) {
		activate-purpose $session $purpose
	}
	move-to-session $session $client_name
}

def repin-workspace [raw_path?: string] {
	let client_name = (current-client)
	let session = (session-for $client_name)
	if ($session | is-empty) {
		print -e "tws repin must run inside tmux"
		return
	}

	let requested = if ($raw_path != null and ($raw_path | is-not-empty)) {
		$raw_path
	} else if ($client_name | is-not-empty) {
		tmux-value display-message -p -t $client_name "#{pane_current_path}"
	} else {
		$env.PWD
	}

	let root = (normalize-root $requested)
	if not ($root | path exists) {
		^tmux display-message $"directory does not exist: ($root)"
		return
	}

	synchronize-session-state $session $root | ignore
	^tmux display-message $"workspace anchored to: ($root)"
}

def related-records [session: string] {
	if ($session | is-empty) {
		return []
	}
	ensure-session-identities
	let id = (ensure-workspace-id $session)
	let root = (session-root $session)
	let common = (ensure-git-common $session $root)
	let state = (load-state)
	let record = (state-record $state $id)
	let manual = ($record.related | default [])
	let excluded = ($record.excluded | default [])
	let others = (session-records | where { |item| $item.id != $id })
	let calculated = if ($common | is-empty) {
		[]
	} else {
		$others | where { |item|
			let item_common = if ($item.git_common | is-empty) {
				let computed = (git-common-for-root $item.root)
				if ($computed | is-not-empty) {
					set-session-option $item.name "@workspace-git-common" $computed
				}
				$computed
			} else {
				normalize-root $item.git_common
			}
			$item_common == $common
		}
	}
	let calculated_ids = ($calculated | each { |item| $item.id })
	$others
	| each { |item|
		{
			name: $item.name,
			id: $item.id,
			root: $item.root,
			mru: $item.mru,
			git_common: $item.git_common,
			manual: ($item.id in $manual),
			calculated: ($item.id in $calculated_ids)
		}
	}
	| where { |item| ($item.manual or $item.calculated) and ($item.id not-in $excluded) }
	| sort-by { |item| $item.name | str downcase }
}

def related-order [current: string, records: list] {
	let sorted = ($records | sort-by { |item| $item.name | str downcase })
	let count = ($sorted | length) + 1
	let center = ($count // 2)
	let current_record = {
		name: $current,
		id: (ensure-workspace-id $current),
		root: (session-root $current),
		mru: 0,
		git_common: "",
		manual: false,
		calculated: false
	}
	($sorted | first $center) ++ [$current_record] ++ ($sorted | skip $center)
}

def clear-pending-options [kind: string, client: string] {
	let pending = (pending-option $kind $client "pending")
	let token = (pending-option $kind $client "token")
	^tmux set-option -gu $pending
	^tmux set-option -gu $token
}

def clear-pending [kind: string, client: string] {
	clear-pending-options $kind $client
	if ($client | is-not-empty) {
		^tmux switch-client -c $client -T root
		^tmux refresh-client -t $client -S
	} else {
		^tmux switch-client -T root
		^tmux refresh-client -S
	}
}

def reset-client-state [client: string] {
	if ($client | is-empty) {
		return
	}
	clear-pending-options "session" $client
	clear-pending-options "related" $client
	clear-pending-options "commit" $client
	^tmux switch-client -c $client -T root
}

def arm-timeout [kind: string, client: string] {
	let token = (date now | into int | into string)
	let option = (pending-option $kind $client "token")
	^tmux set-option -g $option $token
	^tmux run-shell -b $"nu --no-config-file ~/.config/tmux/scripts/workspace.nu timeout ($kind) '($token)' '($client)'"
}

def arm-session-commit [client: string] {
	if ($client | is-empty) {
		return
	}
	let session = (session-for $client)
	if ($session | is-empty) {
		return
	}
	let token = (date now | into int | into string)
	let pending = (pending-option "commit" $client "pending")
	let token_option = (pending-option "commit" $client "token")
	^tmux set-option -g $pending $session
	^tmux set-option -g $token_option $token
	^tmux run-shell -b $"nu --no-config-file ~/.config/tmux/scripts/workspace.nu session-commit-timeout '($token)' '($client)'"
}

def session-commit-duration [] {
	let configured = (global-option "@workspace-session-commit-delay")
	let seconds = (try { $configured | into int } catch { 10 })
	let value = if $seconds > 0 { $seconds } else { 10 }
	$"($value)sec" | into duration
}

def select-session [action: string, client: string] {
	let records = (session-records | sort-by mru --reverse)
	let count = ($records | length)
	if $count == 0 {
		return
	}

	let current = (session-for $client)
	match $action {
		"left" | "right" => {
			let matching = ($records | enumerate | where { |item| $item.item.name == $current })
			let index = if ($matching | is-empty) {
				if $action == "right" { 0 } else { $count - 1 }
			} else {
				$matching | first | get index
			}
			let target = if $action == "right" {
				($index + 1) mod $count
			} else {
				($index - 1 + $count) mod $count
			}
			move-to-session ($records | get $target | get name) $client
		}
		"confirm" => {
			let pending_option = (pending-option "session" $client "pending")
			let pending_raw = (global-option $pending_option)
			let pending_exists = ($records | any { |item| $item.name == $pending_raw })
			let pending = if $pending_exists { $pending_raw } else { $current }
			let target = ($records | where { |item| $item.name == $pending } | get -o 0 | default null)
			if $target != null {
				move-to-session $target.name $client
			}
			clear-pending "session" $client
		}
		"cancel" => { clear-pending "session" $client }
		"kill" => {
			let pending_option = (pending-option "session" $client "pending")
			let pending_raw = (global-option $pending_option)
			let pending_exists = ($records | any { |item| $item.name == $pending_raw })
			let pending = if $pending_exists { $pending_raw } else { $current }
			let target = ($records | where { |item| $item.name == $pending } | get -o 0 | default null)
			if $target != null {
				^tmux kill-session -t $"=($target.name)"
			}
			clear-pending "session" $client
		}
	}
}

def related-pending [client: string] {
	global-option (pending-option "related" $client "pending")
}

def set-related-pending [client: string, name: string] {
	^tmux set-option -g (pending-option "related" $client "pending") $name
}

def enter-related-table [client: string] {
	if ($client | is-not-empty) {
		^tmux switch-client -c $client -T workspace-related
	} else {
		^tmux switch-client -T workspace-related
	}
}

def select-related [action: string, client: string] {
	let current = (session-for $client)
	if ($current | is-empty) {
		return
	}
	let records = (related-records $current)
	let order = (related-order $current $records)
	let count = ($order | length)
	if $count <= 1 {
		clear-pending "related" $client
		return
	}
	let current_index = ($order | enumerate | where { |item| $item.item.name == $current } | first | get index)
	let pending_raw = (related-pending $client)
	let pending_index = if ($pending_raw | is-empty) {
		$current_index
	} else {
		let matching = ($order | enumerate | where { |item| $item.item.name == $pending_raw })
		if ($matching | is-empty) { $current_index } else { $matching | first | get index }
	}

	match $action {
		"cursor-left" | "cursor-right" => {
			let step = if $action == "cursor-right" { 1 } else { -1 }
			let next = (($pending_index + $step) mod $count)
			let name = ($order | get $next | get name)
			set-related-pending $client $name
			arm-timeout "related" $client
			enter-related-table $client
			^tmux refresh-client -S
		}
		"direct-next" | "direct-previous" => {
			let step = if $action == "direct-next" { 1 } else { -1 }
			let target = (($current_index + $step) mod $count)
			let name = ($order | get $target | get name)
			clear-pending-options "related" $client
			if $name != $current {
				move-to-session $name $client
			}
		}
		"confirm" => {
			let target = if ($pending_raw | is-empty) { $current } else { $pending_raw }
			if $target != $current {
				move-to-session $target $client
			}
			clear-pending "related" $client
		}
		"cancel" => { clear-pending "related" $client }
		"unlink" => {
			let target_name = if ($pending_raw | is-empty) { $current } else { $pending_raw }
			if $target_name != $current {
				let target = ($order | where { |item| $item.name == $target_name } | get -o 0 | default null)
				if $target != null {
					let current_id = (ensure-workspace-id $current)
					let current_root = (session-root $current)
					let target_id = if ($target.id | is-not-empty) { $target.id } else { ensure-workspace-id $target_name }
					let target_root = (session-root $target_name)
					let state = (unlink-workspaces (load-state) $current_id $current_root $target_id $target_root)
					let state = if $target.calculated {
						exclude-workspace $state $current_id $current_root $target_id
					} else {
						$state
					}
					save-state $state
					^tmux refresh-client -S
				}
			}
			clear-pending "related" $client
		}
		_ => {}
	}
}

def pick-related [client: string] {
	let current = (session-for $client)
	if ($current | is-empty) {
		return
	}
	ensure-session-identities
	let current_id = (ensure-workspace-id $current)
	let current_root = (session-root $current)
	if ($current_root | is-empty) {
		return
	}
	let related = ((state-record (load-state) $current_id).related | default [])
	let already_related = (related-records $current | each { |item| $item.id })
	let candidates = (session-records | where { |item| $item.id != $current_id and $item.id not-in $related and $item.id not-in $already_related })
	if ($candidates | is-empty) {
		^tmux display-message "no unlinked sessions"
		return
	}

	let input = ($candidates | get name | str join "\n")
	let tmux_fzf = (do { ^which fzf-tmux } | complete)
	let plain_fzf = (do { ^which fzf } | complete)
	let picked = if $tmux_fzf.exit_code == 0 {
		do { $input | ^fzf-tmux -p "70%,60%" --prompt "relate> " } | complete
	} else if $plain_fzf.exit_code == 0 {
		do { $input | ^fzf --height "60%" --reverse --prompt "relate> " } | complete
	} else {
		^tmux display-message "fzf is required to link sessions"
		return
	}

	let name = ($picked.stdout | str trim)
	if ($picked.exit_code != 0 or ($name | is-empty)) {
		return
	}
	let target = ($candidates | where { |item| $item.name == $name } | get -o 0 | default null)
	if $target != null {
		let state = (link-workspaces (load-state) $current_id $current_root $target.id $target.root)
		save-state $state
		^tmux refresh-client -S
	}
}

def move-window-pick [client: string] {
	let current = (session-for $client)
	let window = (current-window $client)
	if ($current | is-empty) or ($window | is-empty) {
		return
	}
	let sessions = (session-records | where { |item| $item.name != $current } | sort-by { |item| $item.name | str downcase })
	if ($sessions | is-empty) {
		^tmux display-message "no other sessions"
		return
	}
	let input = ($sessions | each { |item| $"($item.name)\t($item.root)" } | str join "\n")
	let tmux_fzf = (do { ^which fzf-tmux } | complete)
	let plain_fzf = (do { ^which fzf } | complete)
	let picked = if $tmux_fzf.exit_code == 0 {
		do { $input | ^fzf-tmux -p "70%,60%" --prompt "move tab> " } | complete
	} else if $plain_fzf.exit_code == 0 {
		do { $input | ^fzf --height "60%" --reverse --prompt "move tab> " } | complete
	} else {
		^tmux display-message "fzf is required to move tabs"
		return
	}
	let line = ($picked.stdout | str trim)
	if ($picked.exit_code != 0) or ($line | is-empty) {
		return
	}
	let target_name = ($line | split row "\t" | first)
	let target = ($sessions | where { |item| $item.name == $target_name } | get -o 0 | default null)
	if $target == null {
		return
	}
	let windows = (tmux-value list-windows -t $"=($current)" -F "#{window_id}" | lines | where { |item| $item != "" })
	if ($windows | length) <= 1 {
		create-window $current (current-purpose $current $client) | ignore
	}
	let result = (tmux-result move-window -s $window -t $"=($target.name):")
	if $result.exit_code != 0 {
		^tmux display-message $"could not move tab: ($result.stderr | str trim)"
		return
	}
	move-to-session $target.name $client
	^tmux refresh-client -S
}

def find-session [target: string] {
	ensure-session-identities
	let records = (session-records)
	let by_name = ($records | where { |item| $item.name == $target } | get -o 0 | default null)
	if $by_name != null {
		return $by_name
	}

	let root = (normalize-root $target)
	$records | where { |item| $item.root == $root } | get -o 0 | default null
}

def link-session [target: string, client: string] {
	let current = (session-for $client)
	if ($current | is-empty) {
		return
	}
	let current_id = (ensure-workspace-id $current)
	let current_root = (session-root $current)
	let target_record = (find-session $target)
	if ($target_record == null) {
		^tmux display-message $"unknown workspace: ($target)"
		return
	}
	if $target_record.id == $current_id {
		^tmux display-message "workspace cannot relate to itself"
		return
	}

	save-state (link-workspaces (load-state) $current_id $current_root $target_record.id $target_record.root)
	^tmux refresh-client -S
}

def unlink-session [target: string, client: string] {
	let current = (session-for $client)
	if ($current | is-empty) {
		return
	}
	let current_id = (ensure-workspace-id $current)
	let current_root = (session-root $current)
	let target_record = (find-session $target)
	if ($target_record == null) {
		^tmux display-message $"unknown workspace: ($target)"
		return
	}

	let current_common = (ensure-git-common $current $current_root)
	let target_common = (ensure-git-common $target_record.name $target_record.root)
	let state = (unlink-workspaces (load-state) $current_id $current_root $target_record.id $target_record.root)
	let state = if ($current_common | is-not-empty) and ($current_common == $target_common) {
		exclude-workspace $state $current_id $current_root $target_record.id
	} else {
		$state
	}
	save-state $state
	^tmux refresh-client -S
}

def timeout [kind: string, token: string, client: string] {
	sleep 1sec
	let option = (pending-option $kind $client "token")
	if (global-option $option) == $token {
		clear-pending $kind $client
	}
}

def session-commit-timeout [token: string, client: string] {
	sleep (session-commit-duration)
	let token_option = (pending-option "commit" $client "token")
	if (global-option $token_option) != $token {
		return
	}

	let pending = (global-option (pending-option "commit" $client "pending"))
	let current = (session-for $client)
	if ($pending | is-not-empty) and $pending == $current {
		mark-session-used $current
	}
	clear-pending-options "commit" $client
	^tmux refresh-client -S
}

def client-session-changed [client: string] {
	reset-client-state $client
	arm-session-commit $client
}

def status-style [style: string, text: string] {
	"#[" + $style + "]" + $text + "#[fg=#ffffff,bg=#2f3045,nobold]"
}

def status-sessions [current: string, client: string, key_table: string] {
	let pending = if $key_table == "workspace-session" {
		global-option (pending-option "session" $client "pending")
	} else {
		""
	}
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

def status-related [current: string, client: string, key_table: string] {
	let pending = if $key_table == "workspace-related" {
		global-option (pending-option "related" $client "pending")
	} else {
		""
	}
	let rows = (related-records $current)
	if ($rows | is-empty) {
		print -n (status-style "fg=#a7a7c4,bg=#2f3045" " related: none ")
		return
	}

	let output = ($rows | reduce --fold "" { |row, acc|
		let separator = if ($acc | is-empty) { "" } else { " " }
		let style = if $row.name == $pending {
			"fg=#000000,bg=#e0af68,bold"
		} else {
			"fg=#ffffff,bg=#111111"
		}
		$acc + $separator + (status-style $style (" " + $row.name + " "))
	})
	print -n ($output + "#[fg=#ffffff,bg=#2f3045,nobold]")
}

def status-purposes [session: string, window: string] {
	let active = if ($window | is-empty) { default-purpose } else {
		let value = (window-option $window "@workspace-purpose")
		if ($value | is-empty) { default-purpose } else { $value }
	}
	let rows = (window-records $session | sort-by index)
	let sections = (configured-purposes | each { |purpose|
		let header_style = if $purpose == $active {
			"fg=#1a1b26,bg=#68D57A,bold"
		} else {
			"fg=#707080,bg=#08080d,bold"
		}
		let header = (status-style $header_style (" " + ($purpose | str upcase) + " "))
		let tabs = ($rows | where { |row| $row.purpose == $purpose } | reduce --fold "" { |row, acc|
			let separator = if ($acc | is-empty) { "" } else { " " }
			let style = if $row.id == $window {
				"fg=#1a1b26,bg=#5cb2ed,bold"
			} else {
				"fg=#ffffff,bg=#111111"
			}
			let label = if ($row.name | is-empty) { ($row.index | into string) } else { $row.name }
			$acc + $separator + (status-style $style (" " + $label + " "))
		})
		$header + $tabs
	})
	print -n (($sections | str join "  ") + "#[fg=#ffffff,bg=#2f3045,nobold]")
}

def after-select-window [session: string, window: string] {
	if ($session | is-not-empty) and ($window | is-not-empty) {
		let purpose = (window-option $window "@workspace-purpose")
		if ($purpose | is-not-empty) {
			record-window-use $session $window $purpose
		}
	}
}

def after-new-window [session: string, window: string] {
	if ($window | is-empty) {
		return
	}
	if ($session | is-empty) {
		return
	}
	let pending = (session-option $session "@workspace-new-purpose")
	let active = (session-option $session "@workspace-active-purpose")
	let inherited = if ($pending in (configured-purposes)) {
		$pending
	} else if ($active in (configured-purposes)) {
		$active
	} else {
		default-purpose
	}
	set-window-option $window "@workspace-purpose" $inherited
	if ($pending | is-not-empty) {
		set-session-option $session "@workspace-new-purpose" ""
	}
	record-window-use $session $window $inherited
}

def session-created [session: string] {
	let root = (session-root $session)
	if ($root | is-not-empty) {
		initialize-session $session $root | ignore
	}
}

def initialize-all [] {
	for session in (session-records) {
		if ($session.root | is-not-empty) {
			initialize-session $session.name $session.root | ignore
		}
	}
}

def rename-session [new_name: string, client: string] {
	let current = (session-for $client)
	let records = (session-records)
	let pending = (global-option (pending-option "session" $client "pending"))
	let name = if ($pending | is-not-empty) { $pending } else { $current }
	let target = ($records | where { |item| $item.name == $name } | get -o 0 | default null)
	let renamed = ($new_name | str trim)
	if $target != null and ($renamed | is-not-empty) {
		^tmux rename-session -t $"=($target.name)" $renamed
		synchronize-session-state $renamed (session-root $renamed) | ignore
	}
	clear-pending "session" $client
}

def main [...args: string] {
	let action = ($args | get -o 0 | default "")
	let rest = ($args | skip 1)
	let first = ($rest | get -o 0 | default "")
	let second = ($rest | get -o 1 | default "")

	match $action {
		"open" => { open-workspace $first ($rest | get -o 1 | default null) }
		"repin" => { repin-workspace $first }
		"purpose" => {
			let session = if ($second | is-empty) { session-for "" } else { $second }
			activate-purpose $session $first
		}
		"cycle-purpose" => { cycle-purpose $first $second }
		"new-window" => { new-window-for-client $first }
		"new-window-command" => {
			let command = ($rest | skip 2 | str join " ")
			new-command-window $first $second $command
		}
		"session-created" => { session-created $first }
		"initialize-all" => { initialize-all }
		"after-select-window" => { after-select-window $first $second }
		"after-new-window" => { after-new-window $first $second }
		"select-session" => { select-session $first $second }
		"select-related" => { select-related $first $second }
		"link-pick" => { pick-related $first }
		"move-window-pick" => { move-window-pick $first }
		"link" => { link-session $first $second }
		"unlink" => { unlink-session $first $second }
		"timeout" => { timeout $first $second ($rest | get -o 2 | default "") }
		"session-commit-timeout" => { session-commit-timeout $first $second }
		"client-session-changed" => { client-session-changed $first }
		"rename-session" => { rename-session $first $second }
		"status-sessions" => { status-sessions $first $second ($rest | get -o 2 | default "") }
		"status-related" => { status-related $first $second ($rest | get -o 2 | default "") }
		"status-purposes" => { status-purposes $first $second }
		_ => {
			print -e "usage: workspace.nu open|repin|purpose|cycle-purpose|new-window|new-window-command|select-session|select-related|link-pick|move-window-pick|link|unlink|status-sessions|status-related|status-purposes"
			exit 2
		}
	}
}
