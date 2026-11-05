export def is-windows [] {
	(($env.WINDIR? | default "") | is-not-empty)
}

export def normalize-path [value: string] {
	if ($value | is-empty) {
		return ""
	}
	let expanded = ($value | path expand)
	let resolved = if (is-windows) {
		$expanded
	} else {
		let result = (do { ^realpath $expanded } | complete)
		if $result.exit_code == 0 {
			$result.stdout | str trim
		} else {
			$expanded
		}
	}
	let normalized = ($resolved | str replace -a "\\" "/")
	if (is-windows) {
		$normalized | str downcase
	} else {
		$normalized
	}
}

export def git-toplevel [path: string] {
	if ($path | is-empty) {
		return ""
	}
	let result = (do { ^git -C $path rev-parse --show-toplevel } | complete)
	if $result.exit_code != 0 {
		return ""
	}
	$result.stdout | str trim
}

export def git-common-dir [path: string] {
	if ($path | is-empty) {
		return ""
	}
	let result = (do { ^git -C $path rev-parse --path-format=absolute --git-common-dir } | complete)
	if $result.exit_code != 0 {
		return ""
	}
	$result.stdout | str trim
}

export def git-current-branch [path: string] {
	if ($path | is-empty) {
		return ""
	}
	let result = (do { ^git -C $path branch --show-current } | complete)
	if $result.exit_code != 0 {
		return ""
	}
	$result.stdout | str trim
}

export def git-default-branch [path: string] {
	if ($path | is-empty) {
		return "main"
	}
	let remote = (do { ^git -C $path symbolic-ref refs/remotes/origin/HEAD } | complete)
	if $remote.exit_code == 0 {
		let value = ($remote.stdout | str trim)
		if ($value | is-not-empty) {
			return ($value | str replace refs/remotes/origin/ "")
		}
	}
	for candidate in ["main" "master" "develop"] {
		let local = (do { ^git -C $path show-ref --verify --quiet $"refs/heads/($candidate)" } | complete)
		if $local.exit_code == 0 {
			return $candidate
		}
	}
	"main"
}

def empty-worktree-entry [] {
	{
		path: "",
		head: "",
		branch: "",
		bare: false,
		detached: false,
		prunable: false,
		locked: false
	}
}

export def worktree-entries [path: string] {
	let result = (do { ^git -C $path worktree list --porcelain } | complete)
	if $result.exit_code != 0 {
		return []
	}

	mut entries = []
	mut current = (empty-worktree-entry)
	for line in ($result.stdout | lines) {
		if ($line | is-empty) {
			if ($current.path | is-not-empty) {
				$entries = ($entries | append $current)
			}
			$current = (empty-worktree-entry)
			continue
		}
		let key = ($line | split row " " | first)
		let value = if ($line | str contains " ") {
			$line | str substring (($key | str length) + 1)..
		} else {
			""
		}
		match $key {
			"worktree" => { $current = ($current | upsert path $value) }
			"HEAD" => { $current = ($current | upsert head $value) }
			"branch" => { $current = ($current | upsert branch ($value | str replace --regex '^refs/heads/' '')) }
			"bare" => { $current = ($current | upsert bare true) }
			"detached" => { $current = ($current | upsert detached true) }
			"prunable" => { $current = ($current | upsert prunable true) }
			"locked" => { $current = ($current | upsert locked true) }
			_ => {}
		}
	}
	if ($current.path | is-not-empty) {
		$entries = ($entries | append $current)
	}
	$entries
}

export def worktree-main-entry [entries: list] {
	let regular = ($entries | where { |entry| not $entry.bare })
	if ($regular | is-empty) {
		if ($entries | is-empty) {
			return null
		}
		return ($entries | first)
	}
	$regular | first
}

export def worktree-repo-name [entries: list] {
	let main = (worktree-main-entry $entries)
	if $main == null {
		return ""
	}
	let base = ($main.path | path basename)
	if ($main.bare) {
		$base | str replace --regex '\.git$' ''
	} else {
		$base
	}
}

export def worktree-branch-slug [branch: string] {
	$branch | str replace --all "/" "-"
}

export def worktree-entry-label [entry] {
	if ($entry.branch | is-not-empty) {
		$entry.branch
	} else if ($entry.head | is-not-empty) {
		let short = (($entry.head | str length) | if $in > 8 { 8 } else { $in })
		$"detached-($entry.head | str substring 0..<$short)"
	} else {
		"detached"
	}
}

export def worktree-session-name [entries: list, branch: string] {
	let repo = (worktree-repo-name $entries)
	let slug = (worktree-branch-slug $branch)
	if ($repo | is-empty) {
		$slug
	} else if ($slug | is-empty) {
		$repo
	} else {
		$"($repo)/($slug)"
	}
}

export def worktree-default-path [entries: list, branch: string] {
	let base = ($env.WORKTREE_ROOT? | default "~/worktree" | path expand)
	let repo = (worktree-repo-name $entries)
	let slug = (worktree-branch-slug $branch)
	$base | path join $repo $slug
}

export def worktree-entry-for-branch [entries: list, branch: string] {
	$entries | where { |entry| $entry.branch == $branch } | get -o 0
}

export def worktree-entry-for-path [entries: list, path: string] {
	let normalized = (normalize-path $path)
	$entries | where { |entry| (normalize-path $entry.path) == $normalized } | get -o 0
}

export def worktree-entry-is-main [entries: list, entry] {
	let main = (worktree-main-entry $entries)
	if $main == null or $entry == null {
		return false
	}
	(normalize-path $main.path) == (normalize-path $entry.path)
}
