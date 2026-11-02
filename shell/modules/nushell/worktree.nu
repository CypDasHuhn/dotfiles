const workspace_lib = ($nu.home-dir | path join ".config" "tmux" "scripts" "workspace-lib.nu")
use $workspace_lib *

def workspace-script [] {
	($env.XDG_CONFIG_HOME? | default ($nu.home-dir | path join ".config")) | path join "tmux" "scripts" "workspace.nu"
}

def "nu-complete worktree-local-branches" [] {
	let result = (do { ^git for-each-ref --format="%(refname:short)" refs/heads } | complete)
	if $result.exit_code != 0 {
		return []
	}
	$result.stdout
	| lines
	| where { |branch| $branch | is-not-empty }
	| each { |branch| { value: $branch, description: "local branch" } }
}

def "nu-complete worktree-refs" [] {
	let result = (do { ^git for-each-ref --format="%(refname:short)" refs/heads refs/remotes } | complete)
	if $result.exit_code != 0 {
		return []
	}
	$result.stdout
	| lines
	| where { |ref| $ref | is-not-empty }
	| each { |ref| { value: $ref, description: "base ref" } }
}

def "nu-complete worktree-branches" [] {
	let entries = (worktree-entries $env.PWD)
	if ($entries | is-empty) {
		return []
	}
	$entries
	| where { |entry| $entry.branch | is-not-empty }
	| each { |entry| { value: $entry.branch, description: $entry.path } }
}

def repo-entries [] {
	let entries = (worktree-entries $env.PWD)
	if ($entries | is-empty) {
		error make { msg: "Not inside a Git repository." }
	}
	$entries
}

def repo-main [entries: list] {
	let main = (worktree-main-entry $entries)
	if $main == null {
		error make { msg: "Could not resolve the main worktree." }
	}
	$main
}

def --wrapped run-git [path: string, ...args: string] {
	let result = (do { ^git -C $path ...$args } | complete)
	if $result.exit_code != 0 {
		let message = if ($result.stderr | str trim | is-empty) {
			$result.stdout | str trim
		} else {
			$result.stderr | str trim
		}
		error make { msg: $message }
	}
	$result
}

def ensure-worktree [
	branch: string
	from?
	fallback_from?
] {
	let entries = (repo-entries)
	let existing = (worktree-entry-for-branch $entries $branch)
	if $existing != null {
		if $from != null {
			error make { msg: $"Branch '($branch)' already exists; --from is only for new branches." }
		}
		return $existing
	}

	let main = (repo-main $entries)
	let main_path = (normalize-path $main.path)
	let check = (do { ^git -C $main_path check-ref-format --branch $branch } | complete)
	if $check.exit_code != 0 {
		error make { msg: $"Invalid branch name '($branch)'." }
	}
	if ($main.branch == $branch) {
		error make { msg: $"Branch '($branch)' is checked out in the hub; use `wt ascend ($branch)`." }
	}

	let target = (worktree-default-path $entries $branch)
	if ($target | path exists) {
		error make { msg: $"The worktree path already exists: ($target)" }
	}

	let branch_exists = (do { ^git -C $main_path show-ref --verify --quiet $"refs/heads/($branch)" } | complete).exit_code == 0
	let base = if $from != null {
		$from
	} else if $fallback_from != null {
		$fallback_from
	} else {
		null
	}
	if $branch_exists and $base != null {
		error make { msg: $"Branch '($branch)' already exists; --from is only for new branches." }
	}
	if (not $branch_exists) and $base == null {
		error make { msg: $"Local branch '($branch)' was not found. Pass --from <base> to create it." }
	}
	if $base != null {
		let base_check = (do { ^git -C $main_path rev-parse --verify --quiet $"($base)^{commit}" } | complete)
		if $base_check.exit_code != 0 {
			error make { msg: $"Base ref '($base)' was not found." }
		}
	}

	let parent = ($target | path dirname)
	if not ($parent | path exists) {
		mkdir $parent
	}
	let args = if $branch_exists {
		[worktree add $target $branch]
	} else {
		[worktree add -b $branch $target $base]
	}
	run-git $main_path ...$args | ignore

	let updated = (worktree-entries $main_path)
	let entry = (worktree-entry-for-branch $updated $branch)
	if $entry == null {
		error make { msg: $"Created branch '($branch)' but could not find its worktree." }
	}
	$entry
}

def git-worktree [
	branch: string@"nu-complete worktree-local-branches"
	--from: string@"nu-complete worktree-refs"
] {
	let entry = (ensure-worktree $branch $from null)
	print $"Created worktree '($entry.branch)' at '($entry.path)'."
}

def gwt [
	branch: string@"nu-complete worktree-local-branches"
	--from: string@"nu-complete worktree-refs"
] {
	if $from == null {
		git-worktree $branch
	} else {
		git-worktree $branch --from $from
	}
}

def open-session [path: string] {
	let result = (do { ^nu --no-config-file (workspace-script) open $path } | complete)
	if $result.exit_code != 0 {
		let message = if ($result.stderr | str trim | is-empty) {
			$result.stdout | str trim
		} else {
			$result.stderr | str trim
		}
		error make { msg: $message }
	}
}

def session-roots [] {
	let result = (do { ^tmux list-sessions -F "#{session_name}" } | complete)
	if $result.exit_code != 0 {
		return []
	}
	$result.stdout
	| lines
	| where { |name| $name | is-not-empty }
	| each { |name|
		let stored = (do { ^tmux show-option -t $name -qv "@workspace-root" } | complete)
		let stored_root = if $stored.exit_code == 0 { $stored.stdout | str trim } else { "" }
		let root = if ($stored_root | is-not-empty) {
			$stored_root
		} else {
			let panes = (do { ^tmux list-panes -t $name -F "#{pane_current_path}" } | complete)
			if $panes.exit_code == 0 {
				$panes.stdout | lines | where { |item| $item | is-not-empty } | get -o 0 | default ""
			} else {
				""
			}
		}
		{ name: $name, root: (normalize-path $root) }
	}
}

def finish-worktree [entry, no_switch: bool] {
	if $no_switch {
		print $entry.path
	} else {
		open-session $entry.path
	}
}

def session-for-root [root: string] {
	let normalized = (normalize-path $root)
	session-roots | where { |session| $session.root == $normalized } | get -o 0
}

def "wt new" [
	branch: string@"nu-complete worktree-local-branches"
	--from: string@"nu-complete worktree-refs"
	--no-switch
] {
	let entries = (repo-entries)
	let main = (repo-main $entries)
	let fallback = if $from == null { git-default-branch (normalize-path $main.path) } else { null }
	let entry = (ensure-worktree $branch $from $fallback)
	finish-worktree $entry $no_switch
}

def "wt go" [branch?: string@"nu-complete worktree-branches"] {
	let entries = (repo-entries)
	let target = if ($branch == null) or ($branch | is-empty) {
		git-current-branch $env.PWD
	} else {
		$branch
	}
	if ($target | is-empty) {
		error make { msg: "No branch given and the current checkout is detached." }
	}
	let entry = (worktree-entry-for-branch $entries $target)
	if $entry == null {
		error make { msg: $"No worktree for branch '($target)'. Use `wt new ($target)`." }
	}
	open-session $entry.path
}

def "wt home" [] {
	let entries = (repo-entries)
	let main = (repo-main $entries)
	open-session $main.path
}

def "git-wt-ascend" [
    branch?: string@"nu-complete worktree-branches"
    --as: string
    --sync
    --no-switch
] {
    if ($branch == null) or ($branch | is-empty) {
        if $sync {
            wt-ascend-run --sync --no-switch
        } else if ($as != null) and ($as | is-not-empty) {
            wt-ascend-run --as $as --no-switch
        } else {
            wt-ascend-run --no-switch
        }
    } else if $sync and (($as != null) and ($as | is-not-empty)) {
        wt-ascend-run $branch --as $as --sync --no-switch
    } else if $sync {
        wt-ascend-run $branch --sync --no-switch
    } else if ($as != null) and ($as | is-not-empty) {
        wt-ascend-run $branch --as $as --no-switch
    } else {
        wt-ascend-run $branch --no-switch
    }
}

def "wt ascend" [...args: string] {
    let branch = ($args | where { |item| not ($item | str starts-with "--") } | get -o 0 | default "")
    let as_name = if ("--as" in $args) {
        let idx = (try { ($args | enumerate | where { |item| $item.item == "--as" } | first | get index) } catch { -1 })
        if $idx >= 0 { $args | get -o ($idx + 1) | default "" } else { "" }
    } else { "" }
    let sync = ($args | any { |item| $item == "--sync" })
    let no_switch = ($args | any { |item| $item == "--no-switch" })
    if ($branch | is-empty) {
        wt-ascend-run --as=$as_name --sync=$sync --no-switch=$no_switch
    } else {
        wt-ascend-run $branch --as=$as_name --sync=$sync --no-switch=$no_switch
    }
}

def "wt discover" [path?: string] {
	let target = if ($path == null) or ($path | is-empty) { $env.PWD } else { $path }
	let result = (do { ^nu --no-config-file (workspace-script) discover $target } | complete)
	if $result.exit_code != 0 {
		let message = if ($result.stderr | str trim | is-empty) {
			$result.stdout | str trim
		} else {
			$result.stderr | str trim
		}
		error make { msg: $message }
	}
}

def "wt ls" [] {
	let entries = (repo-entries)
	let sessions = (session-roots)
	$entries
	| each { |entry|
		let normalized = (normalize-path $entry.path)
		let session = ($sessions | where { |item| $item.root == $normalized } | get -o 0)
		{
			session: (if $session == null { "[+]" } else { "[S]" }),
			branch: (worktree-entry-label $entry),
			main: (worktree-entry-is-main $entries $entry),
			path: $entry.path,
			tmux: (if $session == null { "" } else { $session.name })
		}
	}
	| select session branch main path tmux
}

def "wt-ascend-run" [
	branch?: string@"nu-complete worktree-branches"
	--as: string
	--sync
	--no-switch
] {
	let entries = (repo-entries)
	let main = (repo-main $entries)
	let main_path = (normalize-path $main.path)
	let hub_branch = (git-current-branch $main_path)
	let target = if ($branch == null) or ($branch | is-empty) { $hub_branch } else { $branch }
	if ($target | is-empty) {
		error make { msg: "The hub is detached; pass a branch name." }
	}
	let default = (git-default-branch $main_path)
	let elsewhere = (
		$entries
		| where { |entry| ($entry.branch == $target) and ((normalize-path $entry.path) != $main_path) }
		| get -o 0
	)
	if $elsewhere != null {
		error make { msg: $"Branch '($target)' is already checked out at ($elsewhere.path)." }
	}

	if $target != $hub_branch {
		let local = (do { ^git -C $main_path show-ref --verify --quiet $"refs/heads/($target)" } | complete)
		if $local.exit_code != 0 {
			error make { msg: $"Local branch '($target)' was not found." }
		}
		let entry = (ensure-worktree $target null null)
		finish-worktree $entry $no_switch
		return
	}

	let status = (do { ^git -C $main_path status --porcelain=v1 } | complete)
	let dirty = (($status.stdout | str trim) | is-not-empty)
	if ($target == $default) and (($as == null) or ($as | is-empty)) {
		error make { msg: $"The hub is on default branch '($default)'; pass --as <name>." }
	}

	if $target == $default {
		let exists = (do { ^git -C $main_path show-ref --verify --quiet $"refs/heads/($as)" } | complete)
		if $exists.exit_code == 0 {
			error make { msg: $"Branch '($as)' already exists." }
		}
		run-git $main_path branch $as HEAD | ignore
		if $dirty {
			run-git $main_path stash push -u -m $"wt-ascend:($as)" | ignore
		}
		let entry = (ensure-worktree $as null null)
		if $dirty {
			let popped = (do { ^git -C $entry.path stash pop } | complete)
			if $popped.exit_code != 0 {
				error make { msg: $"The worktree was created, but restoring the stash failed. The stash was kept." }
			}
		}
		let remote = (do { ^git -C $main_path rev-parse --verify --quiet $"origin/($default)" } | complete)
		if $remote.exit_code != 0 {
			error make { msg: $"Worktree created at ($entry.path), but origin/($default) is missing; the hub was not reset." }
		}
		run-git $main_path reset --hard $"origin/($default)" | ignore
		finish-worktree $entry $no_switch
		return
	}

	if $dirty {
		run-git $main_path stash push -u -m $"wt-ascend:($target)" | ignore
	}
	let switched = (do { ^git -C $main_path switch $default } | complete)
	if $switched.exit_code != 0 {
		if $dirty {
			do { ^git -C $main_path stash pop } | complete | ignore
		}
		let message = if ($switched.stderr | str trim | is-empty) {
			$switched.stdout | str trim
		} else {
			$switched.stderr | str trim
		}
		error make { msg: $message }
	}
	let entry = (ensure-worktree $target null null)
	if $dirty {
		let popped = (do { ^git -C $entry.path stash pop } | complete)
		if $popped.exit_code != 0 {
			error make { msg: $"The worktree was created, but restoring the stash failed. The stash was kept." }
		}
	}
	if $sync {
		run-git $main_path fetch origin | ignore
		run-git $main_path reset --hard $"origin/($default)" | ignore
	}
	finish-worktree $entry $no_switch
}

def "wt rm" [
	branch: string@"nu-complete worktree-branches"
	--keep-branch
	--force
] {
	let entries = (repo-entries)
	let entry = (worktree-entry-for-branch $entries $branch)
	if $entry == null {
		error make { msg: $"No worktree for branch '($branch)'." }
	}
	if (worktree-entry-is-main $entries $entry) {
		error make { msg: "Refusing to remove the main worktree." }
	}
	let main = (repo-main $entries)
	let session = (session-for-root $entry.path)
	if $session != null {
		let current = if "TMUX" in $env {
			do { ^tmux display-message -p "#S" } | complete | get stdout | str trim
		} else {
			""
		}
		if $session.name == $current {
			let home = (session-for-root $main.path)
			if $home == null {
				error make { msg: "The current session is the worktree session; switch away before removing it." }
			}
			^tmux switch-client -t $"=($home.name)"
		}
		^tmux kill-session -t $"=($session.name)"
	}
	let args = if $force {
		[worktree remove --force $entry.path]
	} else {
		[worktree remove $entry.path]
	}
	run-git $main.path ...$args | ignore
	if not $keep_branch {
		let flag = if $force { "-D" } else { "-d" }
		run-git $main.path branch $flag $branch | ignore
	}
}

def "wt prune" [] {
	let entries = (repo-entries)
	let main = (repo-main $entries)
	run-git $main.path worktree prune | ignore
	let root = (normalize-path ($env.WORKTREE_ROOT? | default "~/worktree" | path expand))
	for session in (session-roots) {
		if (($session.root | str starts-with $root) and (not ($session.root | path exists))) {
			^tmux kill-session -t $"=($session.name)"
		}
	}
}

def "wt sync" [branch?: string@"nu-complete worktree-branches"] {
	let entries = (repo-entries)
	let target = if ($branch == null) or ($branch | is-empty) {
		git-current-branch $env.PWD
	} else {
		$branch
	}
	if ($target | is-empty) {
		error make { msg: "No branch given and the current checkout is detached." }
	}
	let entry = (worktree-entry-for-branch $entries $target)
	if $entry == null {
		error make { msg: $"No worktree for branch '($target)'." }
	}
	let default = (git-default-branch (normalize-path $entry.path))
	run-git $entry.path fetch origin | ignore
	run-git $entry.path rebase --autostash $"origin/($default)" | ignore
}
