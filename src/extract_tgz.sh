#!/bin/bash

#--
# Extract tgz archive $1. If second parameter is existing file or directory, 
# remove before extraction.
#
# @param tgz_file
# @param path (optional - if set check if path was created)
# global SECONDS
#--
function _extract_tgz {
	test -s "$1" || _abort "_extract_tgz: Invalid archive path [$1]"
	local target target_dir base
	target="$2"

	test "${1: -4}" = ".tgz" && base="${1:0:-4}"
	[[ -z "$target" && -n "$base" ]] && target="$base"

	if [[ -n "$target" && -d "$target" ]]; then
		_confirm "remove existing $target" 1
		test "$CONFIRM" = 'y' || return
		_rm "$target"
	fi

	tar -tzf "$1" >/dev/null 2>/dev/null || _abort "_extract_tgz: invalid archive '$1'"

	SECONDS=0

	if [[ "${target:0:1}" = '/' || "$target" =~ .+/.+ ]]; then
		target_dir=$(dirname "$target")
		_msg "extract archive $1 in $target_dir"
		tar -xzf "$1" -C "$target_dir" >/dev/null || _abort "tar -xzf '$1' -C '$target_dir'"
		[[ ! -d "$target" && -d "$target_dir/$base" ]] && _mv "$target_dir/$base" "$target"
	else
		_msg "extract archive $1"
		tar -xzf "$1" >/dev/null || _abort "tar -xzf '$1'"
	fi

	_msg "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."

	if [[ -n "$target" && ! -d "$target" && ! -f "$target" ]]; then
		_abort "$target was not created"
	fi
}

