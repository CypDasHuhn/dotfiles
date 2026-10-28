alias ii='xdg-open'

tmux() {
  if (( $# )); then
    command tmux "$@"
    return
  fi

  if [[ -n "$TMUX" ]]; then
    command tmux
    return
  fi

  command bash "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/scripts/ensure-plugins.sh" || true

  if command tmux list-sessions >/dev/null 2>&1; then
    command tmux attach-session
    return
  fi

  command tmux
}

tmux-workspace() {
  command bash "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/scripts/ensure-plugins.sh" || true
  if [[ "${1:-}" == "repin" ]]; then
    shift
    command nu --no-config-file "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/scripts/workspace.nu" repin "$@"
    return
  fi
  command nu --no-config-file "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/scripts/workspace.nu" open "$@"
}

alias tws=tmux-workspace
