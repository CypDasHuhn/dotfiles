# region Git
alias gc = git commit -m
alias gp = git pull
alias gpr = git pull --rebase
alias gps = git push
alias gs = git status

def git-update [...words: string] {
    let message = $words | str join " "
    git stash
    git pull --rebase
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
# endregion

alias v = nvim
def --wrapped ve [...args] { with-env { NVIM_MINIMAL: "1" } { nvim ...$args } }
alias md = mkdir
alias cl = clear
alias a = arch
alias rld = exec nu

alias vd = vdir_cli
alias vls = vd ls
alias vcd = vd cd

def --wrapped powershell [...args] {
    pwsh ...$args
}
def --wrapped ps1 [...args] {
    pwsh -File ...$args
}
alias claude-danger = claude --dangerously-skip-permissions

# region Dev
alias npm-r = npm run dev
alias npm-t = npm test
alias dn-r = dotnet run
alias dn-r-https = dn-r --launch-profile "https"
alias dn-t = dotnet test
# endregion
