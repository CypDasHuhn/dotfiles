#!/usr/bin/env bash

set -Eeuo pipefail

readonly DEFAULT_USERNAME='cyp'
readonly WHEEL_GROUP='wheel'
readonly SUDOERS_DROPIN='/etc/sudoers.d/10-wheel'
readonly SSHD_CONFIG='/etc/ssh/sshd_config'

fail() {
	printf 'Error: %s\n' "$1" >&2
	exit 1
}

no_root_login=0
positional=()
for arg in "$@"; do
	case "$arg" in
		--no-root-login)
			no_root_login=1
			;;
		-h|--help)
			printf 'usage: %s [--no-root-login] [username]\n' "$0"
			exit 0
			;;
		-*)
			fail "unknown option: $arg"
			;;
		*)
			positional+=("$arg")
			;;
	esac
done

[[ ${#positional[@]} -le 1 ]] || fail "usage: $0 [--no-root-login] [username]"

readonly USERNAME="${positional[0]:-$DEFAULT_USERNAME}"

[[ $EUID -eq 0 ]] || fail 'run this script as root on the server'
[[ "$USERNAME" != 'root' ]] || fail 'refusing to configure root as the new user'
[[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]] || fail "invalid username: $USERNAME"
command -v sshd >/dev/null 2>&1 || fail 'sshd is required'
command -v visudo >/dev/null 2>&1 || fail 'visudo is required'
getent group "$WHEEL_GROUP" >/dev/null 2>&1 || fail "group $WHEEL_GROUP does not exist"

readonly ROOT_AUTHORIZED_KEYS="/root/.ssh/authorized_keys"
[[ -s "$ROOT_AUTHORIZED_KEYS" ]] || fail "$ROOT_AUTHORIZED_KEYS is missing or empty; refusing to build a user with no keys"

if id "$USERNAME" >/dev/null 2>&1; then
	printf 'User %s already exists.\n' "$USERNAME"
else
	useradd --create-home --shell /bin/bash --groups "$WHEEL_GROUP" "$USERNAME"
	printf 'Created user %s.\n' "$USERNAME"
fi

usermod --append --groups "$WHEEL_GROUP" "$USERNAME"

readonly USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"
[[ -n "$USER_HOME" ]] || fail "could not determine home directory for $USERNAME"
readonly USER_SSH_DIR="$USER_HOME/.ssh"

install -d -m 700 -o "$USERNAME" -g "$USERNAME" "$USER_SSH_DIR"

if [[ -s "$USER_SSH_DIR/authorized_keys" ]]; then
	cat "$ROOT_AUTHORIZED_KEYS" "$USER_SSH_DIR/authorized_keys" | sort -u > "$USER_SSH_DIR/authorized_keys.new"
	install -m 600 -o "$USERNAME" -g "$USERNAME" "$USER_SSH_DIR/authorized_keys.new" "$USER_SSH_DIR/authorized_keys"
	rm -f "$USER_SSH_DIR/authorized_keys.new"
else
	install -m 600 -o "$USERNAME" -g "$USERNAME" "$ROOT_AUTHORIZED_KEYS" "$USER_SSH_DIR/authorized_keys"
fi

chown "$USERNAME:$USERNAME" "$USER_HOME"
printf 'Installed authorized_keys for %s.\n' "$USERNAME"

if [[ -f "$SUDOERS_DROPIN" ]]; then
	printf 'Sudoers drop-in %s already exists.\n' "$SUDOERS_DROPIN"
else
	printf '%%%s ALL=(ALL:ALL) ALL\n' "$WHEEL_GROUP" > "$SUDOERS_DROPIN"
	chmod 440 "$SUDOERS_DROPIN"
	if ! visudo -cf "$SUDOERS_DROPIN" >/dev/null 2>&1; then
		rm -f "$SUDOERS_DROPIN"
		fail 'generated sudoers drop-in failed validation'
	fi
	printf 'Enabled sudo for the %s group.\n' "$WHEEL_GROUP"
fi

if [[ -r /dev/tty && -w /dev/tty ]]; then
	printf 'Set a password for %s (used only for sudo, since SSH passwords are disabled).\n' "$USERNAME"
	passwd "$USERNAME" < /dev/tty > /dev/tty 2>&1 || printf 'Warning: password not set; sudo will not work until you set one with passwd %s.\n' "$USERNAME" >&2
else
	printf 'Warning: no terminal available; run "passwd %s" so sudo works.\n' "$USERNAME" >&2
fi

if [[ $no_root_login -eq 1 ]]; then
	readonly SSHD_BACKUP="$SSHD_CONFIG.bak"
	cp -a "$SSHD_CONFIG" "$SSHD_BACKUP"
	if grep -qE '^[[:space:]]*PermitRootLogin' "$SSHD_CONFIG"; then
		sed -i -E 's/^[[:space:]]*PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
	else
		printf '\nPermitRootLogin no\n' >> "$SSHD_CONFIG"
	fi
	if ! sshd -t; then
		mv "$SSHD_BACKUP" "$SSHD_CONFIG"
		fail 'invalid sshd configuration; restored previous config'
	fi
	rm -f "$SSHD_BACKUP"
	systemctl reload-or-restart sshd
	printf 'Disabled direct root SSH login.\n'
fi

printf '\nNext: open a new terminal and verify before closing this session:\n\n'
printf '  ssh %s@%s\n' "$USERNAME" "$(hostname -I 2>/dev/null | awk '{print $1}')"
printf '\nThen confirm sudo works:\n\n'
printf '  sudo -v\n\n'
if [[ $no_root_login -eq 0 ]]; then
	printf 'Root key login is still allowed as a fallback. Once the new user works, rerun with --no-root-login to disable it.\n'
fi
