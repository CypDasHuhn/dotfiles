def update-dotfiles [] {
    cd $env.dotfiles

    git pull
    lua "bootstrap.lua"
}
