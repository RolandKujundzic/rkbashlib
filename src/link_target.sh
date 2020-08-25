#!/bin/bash

#--
# Return link target (even if missing).
# If found return realpath.
#
# @param link
# @export LINK_TARGET_MISSING
# shellcheck disable=SC2034
#--
function _link_target {
	local target
	test -z "$1" && _abort "empty link path"

	target=$(realpath "$1" 2>/dev/null)
	
	if test -z "$target"; then
		target=$(file "$1" | grep -E -o 'symbolic link to .*/webhome/.+' | sed -E 's/symbolic link to //')
		test -z "$target" && _abort "link target detection failed\n$1"
		LINK_TARGET_MISSING=1
	fi

	echo "$target"
}

