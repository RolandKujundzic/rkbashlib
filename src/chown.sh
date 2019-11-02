#!/bin/bash

#------------------------------------------------------------------------------
# Change owner and group of path
#
# @param path 
# @param owner
# @param group 
# @sudo
# @require _abort
#------------------------------------------------------------------------------
function _chown {
	test -z "$1" && _abort "empty path"

	local ENTRY=("$1")
	local a=; local i=;

	if ! test -f "$1" && ! test -d "$1"; then
		while read a; do
			ENTRY+=("$a")
		done <<< `find "$1" 2>/dev/null`
	fi

	test ${#ENTRY[@]} -lt 1 && _abort "invalid path [$1]"

	if test -z "$2" || test -z "$3"; then
		_abort "owner [$2] or group [$3] is empty"
	fi

	for ((i = 0; i < ${#ENTRY[@]}; i++)); do
		local CURR_OWNER=$(stat -c '%U' "${ENTRY[$i]}")
		local CURR_GROUP=$(stat -c '%G' "${ENTRY[$i]}")

		if test -z "$CURR_OWNER" || test -z "$CURR_GROUP"; then
			_abort "stat owner [$CURR_OWNER] or group [$CURR_GROUP] of [${ENTRY[$i]}] failed"
		fi

		if test "$CURR_OWNER" != "$2" || test "$CURR_GROUP" != "$3"; then
			_sudo "chown -R '$2.$3' '${ENTRY[$i]}'"
		fi
	done
}

