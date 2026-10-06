def update-dotfiles [...params: string] {
    cd $env.dotfiles

    git-rebase-default
    lua "bootstrap.lua" ...$params
}
alias ud = update-dotfiles
