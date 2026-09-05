# shellcheck shell=bash

# BASH helper functions for various tasks.

# Determine if an array contains a certain string
lib::helpers::array_contains() {
	local needle=${1} array=("${@:2}")

	if [[ " ${array[*]} " =~ [[:space:]]${needle}[[:space:]] ]]; then
		return 0
	else
		return 1
	fi
}

# Ensure a base-directory for a given path exists
lib::helpers::ensure_existence() {
	local path=${1}

	if [[ ! -e ${path} ]]; then
		mkdir -p "$(dirname "${path}")"
	fi
}
