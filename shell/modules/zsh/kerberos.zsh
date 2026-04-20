[[ -z "$ZSH_VERSION" ]] && return

_kerberos_password_file() {
  printf '%s\n' "${KERBEROS_PASSWORD_FILE:-$HOME/.config/kerberos/dev_vm_password}"
}

_kerberos_runtime_dir() {
  printf '%s\n' "${XDG_RUNTIME_DIR:-/tmp}"
}

_kerberos_pid_file() {
  printf '%s\n' "$(_kerberos_runtime_dir)/ktinit-refresh-${USER}.pid"
}

_kerberos_init_bin() {
  if [[ -n "${KERBEROS_INIT_BIN:-}" ]]; then
    printf '%s\n' "$KERBEROS_INIT_BIN"
  elif command -v ktinit >/dev/null 2>&1; then
    printf '%s\n' "ktinit"
  else
    printf '%s\n' "kinit"
  fi
}

_kerberos_expect_script() {
  printf '%s\n' "${HOME}/dotfiles/shell/modules/shared/kerberos-login.expect"
}

ktinit-refresh() {
  local principal="${KERBEROS_PRINCIPAL:-}"
  local password_file
  local init_bin
  local expect_script

  if [[ -z "$principal" ]]; then
    echo "KERBEROS_PRINCIPAL is not set" >&2
    return 1
  fi

  password_file="$(_kerberos_password_file)"
  if [[ ! -r "$password_file" ]]; then
    echo "Kerberos password file is missing or unreadable: $password_file" >&2
    return 1
  fi

  init_bin="$(_kerberos_init_bin)"
  if ! command -v "$init_bin" >/dev/null 2>&1; then
    echo "Kerberos init command not found: $init_bin" >&2
    return 1
  fi

  expect_script="$(_kerberos_expect_script)"
  if [[ ! -r "$expect_script" ]]; then
    echo "Kerberos expect script is missing: $expect_script" >&2
    return 1
  fi

  expect "$expect_script" "$init_bin" "$principal" "$password_file"
}

ktinit-ensure() {
  if klist -s >/dev/null 2>&1; then
    return 0
  fi

  ktinit-refresh
}

ktinit-watch() {
  local interval="${1:-${KERBEROS_REFRESH_INTERVAL:-900}}"

  if ! [[ "$interval" =~ ^[0-9]+$ ]] || (( interval <= 0 )); then
    echo "Refresh interval must be a positive integer" >&2
    return 1
  fi

  while true; do
    ktinit-ensure >/dev/null 2>&1
    sleep "$interval"
  done
}

ktinit-watch-start() {
  local pid_file
  local interval="${1:-${KERBEROS_REFRESH_INTERVAL:-900}}"
  local pid

  pid_file="$(_kerberos_pid_file)"
  if [[ -r "$pid_file" ]]; then
    pid="$(<"$pid_file")"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
    rm -f "$pid_file"
  fi

  (ktinit-watch "$interval") &
  pid=$!
  printf '%s\n' "$pid" > "$pid_file"
  disown "$pid" 2>/dev/null || true
}

ktinit-watch-stop() {
  local pid_file
  local pid

  pid_file="$(_kerberos_pid_file)"
  if [[ ! -r "$pid_file" ]]; then
    return 0
  fi

  pid="$(<"$pid_file")"
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
  fi
  rm -f "$pid_file"
}

if [[ -o interactive ]] && [[ "${KERBEROS_AUTO_START:-1}" == "1" ]]; then
  if [[ -n "${KERBEROS_PRINCIPAL:-}" ]]; then
    ktinit-watch-start >/dev/null 2>&1
  fi
fi
