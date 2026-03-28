def update-dotfiles [...params: string] {
    cd $env.dotfiles

    git pull
    lua "bootstrap.lua" ...$params
}
alias ud = update-dotfiles
