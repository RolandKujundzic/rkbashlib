#!/bin/bash

#--
# Return link target (even if missing).
# If found return realpath.
#
# @param link
# @param optional 1=abort if missing
# @export LINK_TARGET_MISSING
# shellcheck disable=SC2034
#--
function _link_target {
	local target
	test -z "$1" && _abort "empty link path"

	LINK_TARGET_MISSING=

	if [[ -f "$1" || -d "$1" ]]; then
		target=$(realpath "$1" 2>/dev/null)
	fi

	if [[ -z "$target" && -L "$1" ]]; then
		target=$(file "$1" | grep -E 'symbolic link to ' | sed -E 's/.*symbolic link to //')
		test -z "$target" && _abort "link target detection failed\n$1"
		LINK_TARGET_MISSING=1
	fi

	[[ -z "$target" && "$2" = 1 ]] && _abort "missing link $1"

	echo "$target"
}

