#!/usr/bin/env bash

set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
plugins_dir="$config_dir/plugins"
platform="unix"
if [[ -n "${WINDIR:-}" ]]; then
	platform="windows"
fi

config_files=(
	"$config_dir/options.conf"
	"$config_dir/platform/$platform.conf"
)

# Read only the active platform file. TPM's config scanner does not evaluate
# tmux %if blocks and would otherwise try to install both Unix and Windows
# plugin variants.
plugin_specs=()
while IFS= read -r plugin; do
	[[ -n "$plugin" ]] || continue
	plugin="${plugin#\'}"
	plugin="${plugin%\'}"
	plugin="${plugin#\"}"
	plugin="${plugin%\"}"
	plugin_specs+=("$plugin")
done < <(
	awk '
		/^[[:space:]]*set(-option)?[[:space:]]+-g[[:space:]]+@plugin[[:space:]]+/ {
			print $4
		}
	' "${config_files[@]}" 2>/dev/null
)

[[ ${#plugin_specs[@]} -gt 0 ]] || exit 0

mkdir -p "$plugins_dir"
installed_plugin=false

for plugin in "${plugin_specs[@]}"; do
	plugin_name="${plugin##*/}"
	plugin_name="${plugin_name%.git}"
	plugin_dir="$plugins_dir/$plugin_name"
	[[ -d "$plugin_dir" ]] && continue

	case "$plugin" in
		git@*|git://*|http://*|https://*|ssh://*)
			plugin_url="$plugin"
			;;
		*)
			plugin_url="https://github.com/${plugin%.git}.git"
			;;
	esac

	git clone --quiet "$plugin_url" "$plugin_dir"
	installed_plugin=true
done

# If a server is already running, load newly installed plugins now. A cold
# server will source them from tmux.conf before its first session is created.
if [[ "$installed_plugin" == true ]] && tmux list-sessions >/dev/null 2>&1; then
	tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$plugins_dir"
	tmux source-file "$config_dir/tmux.conf"
fi
