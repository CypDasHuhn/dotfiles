# Dotfiles utilities (mirrors dotfiles.ps1)

def update-dotfiles [] {
    lua $"($env.dotfiles)/bootstrap.lua"
}
