# zsh-specific configuration
# Only runs in zsh

[[ -z "$ZSH_VERSION" ]] && return

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS      # Don't record duplicates
setopt HIST_IGNORE_SPACE     # Don't record commands starting with space
setopt SHARE_HISTORY         # Share history between sessions
setopt APPEND_HISTORY        # Append instead of overwrite

# Directory navigation
setopt AUTO_CD               # cd by typing directory name
setopt AUTO_PUSHD            # Push directories onto stack
setopt PUSHD_IGNORE_DUPS     # Don't push duplicates
setopt PUSHD_SILENT          # Don't print stack after pushd/popd

# Completion
autoload -Uz compinit && compinit
setopt COMPLETE_IN_WORD      # Complete from cursor position
setopt ALWAYS_TO_END         # Move cursor to end after completion
zstyle ':completion:*' menu select                    # Arrow key selection
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'   # Case insensitive

# Misc
setopt INTERACTIVE_COMMENTS  # Allow comments in interactive shell
setopt NO_BEEP               # No beeping

# Prompt
setopt PROMPT_SUBST          # Allow parameter expansion in prompt
PS1='%1~ %# '

# Keybindings
bindkey '^Y' autosuggest-accept  # Ctrl+Y to accept autosuggestion

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
