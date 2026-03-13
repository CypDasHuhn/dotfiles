# Central PATH registry — source this from your shell profile
path_prepend() {
  [[ -d "$1" && ":$PATH:" != *":$1:"* ]] && export PATH="$1:$PATH"
}

# Tools
path_prepend "$HOME/.zvm/bin"
