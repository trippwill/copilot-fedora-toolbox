#!/usr/bin/env bash
set -euo pipefail

image="${COPILOT_TOOLBOX_IMAGE:-localhost/copilot-cli-toolbox:latest}"
container="${COPILOT_TOOLBOX_CONTAINER:-copilot-cli}"
bin_dir="${COPILOT_TOOLBOX_BIN_DIR:-${XDG_BIN_HOME:-$HOME/.local/bin}}"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
recreate=false
install_wrapper=true
refresh_tools=false

usage() {
	cat <<EOF
Usage: ${0##*/} [options]

Build the Copilot CLI Toolbox image, create the Toolbox container, and install
the copilot wrapper to ~/.local/bin by default.

Options:
  --recreate            Remove and recreate the Toolbox container after build.
  --no-install-wrapper  Build/create the Toolbox without installing the wrapper.
  --refresh-tools       Refresh Copilot CLI and mise layers while reusing base packages.
  -h, --help            Show this help text.

Environment:
  COPILOT_TOOLBOX_IMAGE      Image tag to build (default: $image)
  COPILOT_TOOLBOX_CONTAINER  Toolbox container name (default: $container)
  COPILOT_TOOLBOX_BIN_DIR    Wrapper install directory (default: $bin_dir)
EOF
}

require_command() {
	local command_name=$1

	if ! command -v "$command_name" >/dev/null 2>&1; then
		printf 'error: required command not found: %s\n' "$command_name" >&2
		exit 1
	fi
}

toolbox_container_exists() {
	toolbox list --containers 2>/dev/null | awk -v name="$container" '
		$0 ~ /^CONTAINER ID[[:space:]]/ { next }
		{
			for (i = 1; i <= NF; i++) {
				if ($i == name) {
					found = 1
				}
			}
		}
		END { exit found ? 0 : 1 }
	'
}

install_copilot_wrapper() {
	local wrapper_source="$script_dir/copilot"
	local wrapper_target="$bin_dir/copilot"

	if [[ ! -f "$wrapper_source" ]]; then
		printf 'error: wrapper source not found: %s\n' "$wrapper_source" >&2
		exit 1
	fi

	install -d "$bin_dir"
	install -m 0755 "$wrapper_source" "$wrapper_target"
	printf 'Installed copilot wrapper to %s\n' "$wrapper_target"

	case ":$PATH:" in
	*":$bin_dir:"*) ;;
	*)
		printf 'warning: %s is not on PATH; add it before running copilot\n' "$bin_dir" >&2
		;;
	esac
}

while (($#)); do
	case "$1" in
	--recreate)
		recreate=true
		;;
	--no-install-wrapper)
		install_wrapper=false
		;;
	--refresh-tools)
		refresh_tools=true
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		printf 'error: unknown option: %s\n\n' "$1" >&2
		usage >&2
		exit 2
		;;
	esac
	shift
done

require_command podman
require_command toolbox
require_command install

build_args=(-t "$image")

if [[ "$refresh_tools" == true ]]; then
	build_args+=(--build-arg "TOOLS_REFRESH=$(date +%s)")
fi

podman build "${build_args[@]}" "$script_dir"

if toolbox_container_exists; then
	if [[ "$recreate" == true ]]; then
		printf 'Removing existing Toolbox container %s\n' "$container"
		toolbox rm --force "$container"
	else
		printf 'Toolbox %s already exists\n' "$container"
		if [[ "$refresh_tools" == true ]]; then
			printf 'warning: refreshed image will not affect %s until the Toolbox is recreated\n' "$container" >&2
		fi
	fi
fi

if ! toolbox_container_exists; then
	toolbox create --image "$image" "$container"
fi

if [[ "$install_wrapper" == true ]]; then
	install_copilot_wrapper
fi
