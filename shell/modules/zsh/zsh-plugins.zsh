# zsh plugins
# Only runs in zsh
# Dependencies defined in dependencies.lua

[[ -z "$ZSH_VERSION" ]] && return

# Syntax highlighting - colors commands as you type
# Install: pacman -S zsh-syntax-highlighting (Arch)
#          apt install zsh-syntax-highlighting (Debian/Ubuntu)
#          brew install zsh-syntax-highlighting (macOS)
_zsh_syntax_paths=(
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
)
for p in "${_zsh_syntax_paths[@]}"; do
    [[ -f "$p" ]] && source "$p" && break
done

# Autosuggestions - ghost text from history, press -> to accept
# Install: pacman -S zsh-autosuggestions (Arch)
#          apt install zsh-autosuggestions (Debian/Ubuntu)
#          brew install zsh-autosuggestions (macOS)
_zsh_autosuggest_paths=(
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
)
for p in "${_zsh_autosuggest_paths[@]}"; do
    [[ -f "$p" ]] && source "$p" && break
done

unset _zsh_syntax_paths _zsh_autosuggest_paths
