#!/usr/bin/env bash
#
# Configure the current Linux machine with custom hostnames for localhost in order to get the correct routing
# in staging and development environments.

set -euo pipefail

# Load the installed core from the directory exported by libsh's installer.
LIB_DIR=${LIBSH_DIR:-}
if [[ -z $LIB_DIR || ! -r $LIB_DIR/lib.sh ]]; then
	printf 'Cannot find libsh. Set LIBSH_DIR to the installed directory containing lib.sh.\n' >&2
	printf 'Install libsh from https://github.com/adnoctem/libsh#readme and use the export printed by the installer.\n' >&2
	exit 1
fi

LIB_DIR=$(cd -P -- "$LIB_DIR" && pwd) || exit 1
# shellcheck source=lib/lib.sh
# shellcheck disable=SC1091
if ! . "$LIB_DIR/lib.sh"; then
	printf 'Could not load libsh at %s; install a complete release from https://github.com/adnoctem/libsh#readme.\n' "$LIB_DIR" >&2
	exit 1
fi

for required in lib::load lib::log::print_error lib::log::print_notice \
	lib::log::print_info lib::log::print_success lib::log::print_debug lib::os::root_exec \
	lib::fs::file_exists lib::fs::file_empty lib::fs::file_writable \
	lib::fs::file_replace_content_multiline lib::fs::file_append_content_after_last_match; do
	if ! declare -F "$required" >/dev/null; then
		printf 'Incompatible libsh at %s; install an updated release from https://github.com/adnoctem/libsh#readme.\n' "$LIB_DIR" >&2
		exit 1
	fi
done
unset required

# Resolve this consumer for the fresh shell used by privileged edits.
HOSTS_SCRIPT=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")

# Constants
HOST_CONFIGS=(
	'/etc/hosts'
)

CONFIG_START="# CHARTS MANAGED START"
CONFIG_END="# CHARTS MANAGED END"

CONFIG=$(
	cat <<EOF
${CONFIG_START}
# This file is managed by Ad Noctem Collective's Helm Charts - do not modify!

# adnoctem/helm - Ad Noctem Collective Helm Charts
127.0.0.1               linkwarden.charts.internal         # Linkwarden
127.0.0.1               vaultwarden.charts.internal        # Vaultwarden
127.0.0.1               uptime-kuma.charts.internal        # Uptime-Kuma
127.0.0.1               paperless.charts.internal          # Paperless-NGX
127.0.0.1               gotenberg.charts.internal          # Gotenberg
127.0.0.1               linkstack.charts.internal          # Linkstack
127.0.0.1               ntfy.charts.internal               # ntfy
127.0.0.1               cachet.charts.internal             # Cachet
127.0.0.1               gobackup.charts.internal           # GoBackup
127.0.0.1               activepieces.charts.internal       # Activepieces
127.0.0.1               outline.charts.internal            # Outline
127.0.0.1               glance.charts.internal             # Glance
127.0.0.1               lhci.charts.internal               # Lighthouse CI

${CONFIG_END}
EOF
)
# ----------------------
#   'help' usage function
# ----------------------
function hosts::usage() {
	echo
	echo "Usage: $(basename "${0}") <COMMAND>"
	echo
	echo "add     - Insert the new configuration in ${HOST_CONFIGS[*]}"
	echo "remove  - Remove the configuration from ${HOST_CONFIGS[*]}"
	echo "help    - Print this usage information"
	echo
}

#######################################
# Edit one hosts file using core APIs; marker validation belongs to this consumer.
# Globals:
#   CONFIG_START, CONFIG_END, CONFIG (read)
# Arguments:
#   1 - add or remove
#   2 - Hosts file path
# Outputs:
#   Library diagnostics on stderr.
# Returns:
#   0 success/no block to remove, nonzero for invalid markers or edit failure.
#######################################
function hosts::edit() {
	local operation=$1 cfg=$2 line inside=0 blocks=0
	local pattern replacement

	case "$operation" in
	add | remove) ;;
	*)
		lib::log::print_error "Unknown hosts operation: $operation"
		return 2
		;;
	esac

	if ! lib::fs::file_exists "$cfg" || [[ ! -r $cfg ]]; then
		lib::log::print_error "Hosts file is not a readable regular file: $cfg"
		return 1
	fi

	# Never let a greedy multiline match consume unrelated text between blocks.
	while IFS= read -r line || [[ -n $line ]]; do
		if [[ $line == "$CONFIG_START" ]]; then
			if [[ $inside == 1 || $blocks != 0 ]]; then
				lib::log::print_error "Duplicate or nested managed hosts blocks in $cfg; resolve them before editing."
				return 1
			fi
			inside=1
		elif [[ $line == "$CONFIG_END" ]]; then
			if [[ $inside == 0 ]]; then
				lib::log::print_error "Unmatched managed hosts end marker in $cfg."
				return 1
			fi
			inside=0
			blocks=$((blocks + 1))
		fi
	done <"$cfg"

	if [[ $inside == 1 ]]; then
		lib::log::print_error "Unclosed managed hosts block in $cfg."
		return 1
	fi

	if [[ $blocks == 1 ]]; then
		lib::log::print_debug "Found an existing managed hosts block in $cfg."

		# Markers are fixed literals containing no ERE metacharacters. Match whole
		# lines and retain the boundary before the block; consume its final newline.
		pattern='(^|\n)'
		pattern+="$CONFIG_START"'\n([^\n]*\n)*'
		pattern+="$CONFIG_END"'(\n|$)'
		replacement='\1'

		if [[ $operation == add ]]; then
			# Replacement uses sed syntax; quote literal backslashes and ampersands.
			replacement=${CONFIG//\\/\\\\}
			replacement=${replacement//&/\\&}
			replacement='\1'"$replacement"
			replacement+='\3'
		fi

		lib::fs::file_replace_content_multiline "$cfg" "$pattern" "$replacement" --in-place
	elif [[ $operation == add ]]; then
		lib::log::print_debug "Adding the first managed hosts block to $cfg."

		if lib::fs::file_empty "$cfg"; then
			# Insertion-after-match has no line to match in an empty file.
			replacement=${CONFIG//\\/\\\\}
			replacement=${replacement//&/\\&}
			lib::fs::file_replace_content_multiline "$cfg" '^$' "$replacement"$'\n' --in-place
		else
			lib::fs::file_append_content_after_last_match "$cfg" '.*' "$CONFIG"$'\n' --in-place
		fi
	else
		lib::log::print_debug "No managed hosts block to remove from $cfg."
		return 0
	fi
}

#######################################
# Confirm and apply one operation, loading core explicitly for elevated edits.
# Globals:
#   HOST_CONFIGS, LIB_DIR, HOSTS_SCRIPT (read)
# Arguments:
#   1 - add or remove
# Outputs:
#   Progress on stdout; confirmation and errors on stderr.
# Returns:
#   0 success, nonzero cancellation or edit failure.
#######################################
function hosts::apply() {
	local operation=$1 cfg choice

	lib::log::print_info "Preparing '$operation' for ${HOST_CONFIGS[*]}"
	read -rp "Modify the system host files ${HOST_CONFIGS[*]}? (y/N) " choice || return 1
	case "$choice" in
	y | Y) ;;
	*)
		lib::log::print_notice 'Cancelled; no changes made.'
		return 1
		;;
	esac

	for cfg in "${HOST_CONFIGS[@]}"; do
		# In-place commits need file-write access, including on Windows mounts.
		if lib::fs::file_writable "$cfg"; then
			hosts::edit "$operation" "$cfg" || return $?
		else
			# Preserve exported settings such as LIBSH_DEBUG. A new Bash still needs
			# to source its functions; pass the resolved library directory explicitly.
			# shellcheck disable=SC2016
			lib::os::root_exec --preserve-environment -- bash -c '
        LIBSH_DIR=$1
        source "$2" || exit
        hosts::edit "$3" "$4"
      ' _ "$LIB_DIR" "$HOSTS_SCRIPT" "$operation" "$cfg" || return $?
		fi

		lib::log::print_success "Finished '$operation' for $cfg."
	done
}

# --------------------------------
#   MAIN
# --------------------------------
function main() {
	local cmd=${1:-help}

	if [[ $# -gt 1 ]]; then
		HOST_CONFIGS+=("${@:2}")
	fi

	# add custom environment variable
	if [[ -n ${EXTRA_HOSTS_PATH:-} ]]; then
		HOST_CONFIGS+=("${EXTRA_HOSTS_PATH}")
	fi

	case "${cmd}" in
	help | --help | -h)
		hosts::usage
		;;
	add)
		hosts::apply add
		return $?
		;;
	remove)
		hosts::apply remove
		return $?
		;;
	*)
		lib::log::print_error "Unknown command: ${cmd}. See 'help' command for usage information:"
		hosts::usage
		return 1
		;;
	esac
}

# ------------
# 'main' call
# ------------
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
	main "$@"
fi
