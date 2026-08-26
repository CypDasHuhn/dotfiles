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
