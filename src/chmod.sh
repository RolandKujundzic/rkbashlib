#!/bin/bash

#------------------------------------------------------------------------------
# Change mode of path $2 to $1. If chmod failed try sudo.
#
# @param file mode (octal)
# @param file path
# @require _abort _sudo
#------------------------------------------------------------------------------
function _chmod {
	test -z "$2" && _abort "empty path"

	local ENTRY=()
	local a=; local i=;

	if ! test -f "$2" && ! test -d "$2"; then
		while read a; do
			ENTRY+=("$a")
		done <<< `find "$2" 2>/dev/null`
	else
		ENTRY+=("$2")
	fi

	test ${#ENTRY[@]} -lt 1 && _abort "invalid path [$2]"

	if test -z "$1"; then
		_abort "empty privileges parameter"
	fi

	local tmp=`echo "$1" | sed -e 's/[012345678]*//'`

	if ! test -z "$tmp"; then
		_abort "invalid octal privileges '$1'"
	fi

	for ((i = 0; i < ${#ENTRY[@]}; i++)); do
		local PRIV=`stat -c "%a" "${ENTRY[$i]}"`

		if test "$1" != "$PRIV" && test "$1" != "0$PRIV"; then
			_sudo "chmod -R $1 '${ENTRY[$i]}'" 1
		fi
	done
}

