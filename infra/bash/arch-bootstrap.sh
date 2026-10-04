#!/usr/bin/env bash

set -Eeuo pipefail

readonly DOTFILES_DIR="$HOME/dotfiles"
readonly DOTFILES_HTTPS_URL="https://github.com/CypDasHuhn/dotfiles.git"
readonly DOTFILES_SSH_URL="git@github.com:CypDasHuhn/dotfiles.git"
readonly SSH_DIR="$HOME/.ssh"
readonly SSH_PRIVATE_KEY="$SSH_DIR/id_ed25519"
readonly SSH_PUBLIC_KEY="$SSH_PRIVATE_KEY.pub"
readonly SSH_KNOWN_HOSTS="$SSH_DIR/known_hosts"
readonly SSH_KEY_COMMENT="Martinfischer533@gmail.com"

fail() {
	printf 'Error: %s\n' "$1" >&2
	exit 1
}

[[ $EUID -ne 0 ]] || fail 'run this script as your user, not as root'
command -v pacman >/dev/null 2>&1 || fail 'pacman is required; this script currently supports Arch Linux only'
command -v sudo >/dev/null 2>&1 || fail 'sudo is required to install Arch packages'

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

sudo pacman -S --needed openssh nushell lua git

if [[ -e "$SSH_PRIVATE_KEY" && ! -f "$SSH_PRIVATE_KEY" ]]; then
	fail "$SSH_PRIVATE_KEY exists but is not a regular file"
fi

if [[ -e "$SSH_PUBLIC_KEY" && ! -f "$SSH_PUBLIC_KEY" ]]; then
	fail "$SSH_PUBLIC_KEY exists but is not a regular file"
fi

if [[ -f "$SSH_PUBLIC_KEY" && ! -f "$SSH_PRIVATE_KEY" ]]; then
	fail "$SSH_PUBLIC_KEY exists without its private key"
fi

if [[ ! -f "$SSH_PRIVATE_KEY" ]]; then
	ssh-keygen -t ed25519 -C "$SSH_KEY_COMMENT" -f "$SSH_PRIVATE_KEY"
fi

if [[ ! -f "$SSH_PUBLIC_KEY" ]]; then
	ssh-keygen -y -f "$SSH_PRIVATE_KEY" > "$SSH_PUBLIC_KEY"
fi

chmod 600 "$SSH_PRIVATE_KEY"
chmod 644 "$SSH_PUBLIC_KEY"

touch "$SSH_KNOWN_HOSTS"
chmod 600 "$SSH_KNOWN_HOSTS"

if ! ssh-keygen -F github.com -f "$SSH_KNOWN_HOSTS" >/dev/null 2>&1; then
	ssh-keyscan -t ed25519 github.com >> "$SSH_KNOWN_HOSTS"
fi

if [[ "$(getent passwd "$(id -u)" | cut -d: -f7)" != "/usr/bin/nu" ]]; then
	chsh -s /usr/bin/nu
fi

if [[ -d "$DOTFILES_DIR" ]]; then
	git -C "$DOTFILES_DIR" rev-parse --show-toplevel >/dev/null 2>&1 \
		|| fail "$DOTFILES_DIR exists but is not a Git checkout"
elif [[ -e "$DOTFILES_DIR" ]]; then
	fail "$DOTFILES_DIR exists but is not a directory"
else
	git clone "$DOTFILES_HTTPS_URL" "$DOTFILES_DIR"
fi

(
	cd "$DOTFILES_DIR"
	lua bootstrap.lua
)

printf '\nAdd this SSH public key to GitHub:\n\n'
cat "$SSH_PUBLIC_KEY"
printf '\n'

[[ -r /dev/tty && -w /dev/tty ]] || fail 'an interactive terminal is required to continue after adding the SSH key'

while true; do
	printf "After adding the key, enter 'continue' to test the SSH remote: " > /dev/tty
	IFS= read -r response < /dev/tty || fail 'could not read the continuation prompt'
	if [[ "$response" == 'continue' ]]; then
		break
	fi
	printf "Please enter exactly 'continue'.\n" > /dev/tty
done

origin_url="$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null || true)"
[[ -n "$origin_url" ]] || fail "$DOTFILES_DIR has no origin remote"

case "$origin_url" in
	http://*|https://*)
		git -C "$DOTFILES_DIR" remote set-url origin "$DOTFILES_SSH_URL"
		;;
esac

git -C "$DOTFILES_DIR" fetch origin
printf 'GitHub SSH remote verified.\n'
