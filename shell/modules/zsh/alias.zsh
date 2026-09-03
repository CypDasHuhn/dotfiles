alias ii='xdg-open'

# With no arguments, resume tmux instead of creating a new session. A cold
# server needs a detached bootstrap session so Continuum can restore saved ones.
tmux() {
  if (( $# )); then
    command tmux "$@"
    return
  fi

  if [[ -n "$TMUX" ]]; then
    command tmux
    return
  fi

  if command tmux has-session 2>/dev/null; then
    command tmux attach-session
    return
  fi

  command tmux new-session -d -s __tmux_restore__
  sleep 1.5
  command tmux attach-session
}
