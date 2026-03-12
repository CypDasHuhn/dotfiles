# bash-specific configuration

# History
HISTFILE=~/.bash_history
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoredups:ignorespace

# Append to history instead of overwriting
shopt -s histappend

# Directory navigation
shopt -s autocd 2>/dev/null  # cd by typing directory name (bash 4+)
shopt -s cdspell             # autocorrect minor typos in cd

# Misc
shopt -s checkwinsize        # update LINES/COLUMNS after each command

export EDITOR="nvim"

# Prompt
PS1='\W \$ '

# Keybindings (readline)
bind '"\C-y": accept-suggestion' 2>/dev/null || true
