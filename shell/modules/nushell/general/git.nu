const _git_completions = ($nu.data-dir | path join "nu_scripts/custom-completions/git/git-completions.nu")
const _git_completions_path = if ($_git_completions | path exists) {
    $_git_completions
} else {
    path self empty.nu
}

use $_git_completions_path *
alias gc = git commit -m
alias gp = git pull
alias gps = git push
alias gs = git status

def git-update [...words: string] {
    let message = $words | str join " "
    git stash
    git pull
    if $env.LAST_EXIT_CODE != 0 {
        git rebase --abort
        git stash pop
        error make { msg: "Pull --rebase failed (merge conflict). Aborted rebase." }
    }
    git stash pop
    git add -u
    git commit -m $message
    if $env.LAST_EXIT_CODE != 0 {
        error make { msg: "Commit failed." }
    }
    git push
}
alias gi = git-update

# Restore file(s) from the remote's default branch (e.g. origin/main),
# resolved dynamically via refs/remotes/origin/HEAD.
def git-restore [...files: string] {
    let default_ref = (git symbolic-ref refs/remotes/origin/HEAD | str trim)
    git restore --source $default_ref -- ...$files
}

def git-rebase-default [] {
    git fetch origin

    let default_branch = (
        git symbolic-ref refs/remotes/origin/HEAD
        | str trim
        | str replace "refs/remotes/origin/" ""
    )
    let target = $"refs/remotes/origin/($default_branch)"

    git rebase --autostash $target
}
alias gpr = git-rebase-default

def git-worktree-repo-name [] {
    let result = (do -i { ^git rev-parse --path-format=absolute --git-common-dir } | complete)
    if $result.exit_code != 0 {
        error make { msg: "Not inside a Git repository." }
    }

    let common_dir = ($result.stdout | str trim | path expand)
    let common_name = ($common_dir | path basename)
    if $common_name == ".git" {
        $common_dir | path dirname | path basename
    } else {
        $common_name | str replace --regex "\\.git$" ""
    }
}

def "nu-complete git-worktree-local-branches" [] {
    let result = (do -i { ^git for-each-ref --format="%(refname:short)" refs/heads } | complete)
    if $result.exit_code != 0 {
        return []
    }

    $result.stdout
    | lines
    | where { |branch| $branch | is-not-empty }
    | each { |branch| { value: $branch, description: "local branch" } }
}

def "nu-complete git-worktree-base-refs" [] {
    let result = (do -i { ^git for-each-ref --format="%(refname:short)" refs/heads refs/remotes } | complete)
    if $result.exit_code != 0 {
        return []
    }

    $result.stdout
    | lines
    | where { |ref| $ref | is-not-empty }
    | each { |ref| { value: $ref, description: "base ref" } }
}

def git-worktree [
    branch: string@"nu-complete git-worktree-local-branches"
    --from: string@"nu-complete git-worktree-base-refs"
] {
    let repo_name = (git-worktree-repo-name)
    let ref_check = (do -i { ^git check-ref-format --branch $branch } | complete)
    if $ref_check.exit_code != 0 {
        error make { msg: $"Invalid branch name '($branch)'." }
    }

    let branch_slug = ($branch | str replace --all "/" "-")
    let target_path = ("~/worktree" | path expand | path join $repo_name | path join $branch_slug)
    if ($target_path | path exists) {
        error make { msg: $"The worktree path already exists: ($target_path)" }
    }

    let branch_check = (do -i { ^git show-ref --verify --quiet $"refs/heads/($branch)" } | complete)
    if $branch_check.exit_code == 0 and $from != null {
        error make { msg: $"Branch '($branch)' already exists; --from is only for new branches." }
    }
    if $branch_check.exit_code != 0 and $from == null {
        error make { msg: $"Local branch '($branch)' was not found. Pass --from <base> to create it." }
    }

    if $from != null {
        let base_check = (do -i { ^git rev-parse --verify --quiet $"($from)^{commit}" } | complete)
        if $base_check.exit_code != 0 {
            error make { msg: $"Base ref '($from)' was not found." }
        }
    }

    let parent = ($target_path | path dirname)
    if not ($parent | path exists) {
        mkdir $parent
    }

    let args = if $branch_check.exit_code == 0 {
        [worktree add $target_path $branch]
    } else {
        [worktree add -b $branch $target_path $from]
    }
    let result = (do -i { ^git ...$args } | complete)
    if $result.exit_code != 0 {
        let message = if ($result.stderr | str trim | is-empty) {
            $result.stdout | str trim
        } else {
            $result.stderr | str trim
        }
        error make { msg: $message }
    }

    print $"Created worktree '($branch)' at '($target_path)'."
}

def gwt [
    branch: string@"nu-complete git-worktree-local-branches"
    --from: string@"nu-complete git-worktree-base-refs"
] {
    if $from == null {
        git-worktree $branch
    } else {
        git-worktree $branch --from $from
    }
}

#region rotate branch

def git-rotate-branch-diff [
    base?: string
    --suffix: string = "-old"
] {
    let repo_root = (git rev-parse --show-toplevel | str trim)
    if $env.LAST_EXIT_CODE != 0 or ($repo_root | is-empty) {
        error make { msg: "Not inside a Git repository." }
    }

    cd $repo_root

    let source_branch = (git branch --show-current | str trim)
    if $env.LAST_EXIT_CODE != 0 or ($source_branch | is-empty) {
        error make { msg: "The current checkout is not on a local branch." }
    }

    let base_ref = if $base == null {
        let remote_head = (do -i { ^git symbolic-ref refs/remotes/origin/HEAD } | complete)
        if $remote_head.exit_code == 0 and not ($remote_head.stdout | str trim | is-empty) {
            $remote_head.stdout | str trim | str replace "refs/remotes/" ""
        } else {
            "develop"
        }
    } else {
        $base
    }

    if $source_branch == $base_ref {
        error make { msg: "The source branch and base branch must differ." }
    }

    let base_check = (do -i { ^git rev-parse --verify $base_ref } | complete)
    if $base_check.exit_code != 0 {
        error make { msg: $"Base ref '($base_ref)' was not found." }
    }

    let old_branch = $source_branch + $suffix
    let old_branch_check = (
        do -i { ^git show-ref --verify --quiet $"refs/heads/($old_branch)" } | complete
    )
    if $old_branch_check.exit_code == 0 {
        error make { msg: $"Branch '($old_branch)' already exists." }
    }

    let merge_base = (do -i { ^git merge-base $base_ref $source_branch } | complete)
    if $merge_base.exit_code != 0 or ($merge_base.stdout | str trim | is-empty) {
        error make { msg: $"Branches '($base_ref)' and '($source_branch)' have no common ancestor." }
    }

    let diff_result = (do -i { ^git diff --binary $"($base_ref)...($source_branch)" } | complete)
    if $diff_result.exit_code != 0 {
        error make { msg: "Could not capture the committed branch diff." }
    }

    let patch = $diff_result.stdout
    if ($patch | str length) == 0 {
        error make { msg: $"No committed diff exists from '($base_ref)' to '($source_branch)'." }
    }

    let dirty = ((git status --porcelain=v1 | str trim) != "")
    let temp_dir = [$env.TMPDIR? $env.TEMP? $env.TMP? "/tmp"] | compact | first
    let patch_file = $temp_dir | path join $"git-rotate-branch-($nu.pid)-((random chars --length 12)).patch"
    $patch | save --force $patch_file

    if $dirty {
        git stash push --include-untracked --message $"temporary branch rotation for ($source_branch)"
        if $env.LAST_EXIT_CODE != 0 {
            rm --force $patch_file
            error make { msg: "Could not stash the current worktree." }
        }
    }

    git branch --move $old_branch
    if $env.LAST_EXIT_CODE != 0 {
        rm --force $patch_file
        error make { msg: $"Could not rename '($source_branch)' to '($old_branch)'." }
    }

    git switch --create $source_branch $base_ref
    if $env.LAST_EXIT_CODE != 0 {
        rm --force $patch_file
        error make { msg: $"Could not create '($source_branch)' from '($base_ref)'." }
    }

    git apply --3way $patch_file
    if $env.LAST_EXIT_CODE != 0 {
        error make { msg: $"Could not apply the diff. The stash was kept when needed, and the patch is at '($patch_file)'." }
    }

    if $dirty {
        git stash pop
        if $env.LAST_EXIT_CODE != 0 {
            error make { msg: "The branch diff applied, but restoring the worktree stash failed. Resolve the conflict and drop the kept stash when finished." }
        }
    }

    git reset
    rm --force $patch_file

    print $"Created '($source_branch)' from '($base_ref)' and preserved the previous branch as '($old_branch)'."
}
#endregion

def update-dotfiles [...params: string] {
    cd $env.dotfiles
    git-rebase-default
    lua "bootstrap.lua" ...$params
}
alias ud = update-dotfiles
