alias ii='xdg-open'

# With no arguments, resume tmux instead of creating a new session. On a cold
# server, invoking tmux directly lets Continuum restore into its normal
# temporary startup session, which Resurrect removes when appropriate.
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

  # Older versions of this wrapper created __tmux_restore__ as a bootstrap
  # session. Remove it so it cannot be kept alive or saved again.
  if command tmux has-session -t =__tmux_restore__ 2>/dev/null; then
    command tmux kill-session -t =__tmux_restore__ 2>/dev/null
  fi

  if command tmux list-sessions >/dev/null 2>&1; then
    command tmux attach-session
    return
  fi

  command tmux
}
