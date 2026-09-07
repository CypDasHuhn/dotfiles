def --wrapped v [...args] {
    with-env { NVIM_PROFILE: $env.nvimProfile } { nvim ...$args }
}
def --wrapped vl [...args] { with-env { NVIM_PROFILE: "low" } { nvim ...$args } }
def --wrapped vm [...args] { with-env { NVIM_PROFILE: "medium" } { nvim ...$args } }
def --wrapped vh [...args] { with-env { NVIM_PROFILE: "high" } { nvim ...$args } }
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
alias copilot-danger = copilot --allow-all


# region Dev
alias npm-r = npm run dev
alias npm-t = npm test
alias dn-r = dotnet run
alias dn-r-https = dn-r --launch-profile "https"
alias dn-t = dotnet test
# endregion
