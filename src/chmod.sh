#!/bin/bash

#------------------------------------------------------------------------------
# Change mode of path $2 to $1. If chmod failed try sudo.
# Use _find first to chmod all FOUND entries.
#
# @param file mode (octal)
# @param file path (if path is empty use $FOUND)
# global CHMOD (default chmod -R)
# @require _abort _sudo
#------------------------------------------------------------------------------
function _chmod {
	test -z "$1" && _abort "empty privileges parameter"
	test -z "$2" && _abort "empty path"

	local tmp=`echo "$1" | sed -e 's/[012345678]*//'`
	test -z "$tmp" || _abort "invalid octal privileges '$1'"

	local CMD="chmod -R"
	if ! test -z "$CHMOD"; then
		CMD="$CHMOD"
		CHMOD=
	fi

	local a=; local i=; local PRIV=;

	if test -z "$2"; then
		for ((i = 0; i < ${#FOUND[@]}; i++)); do
			PRIV=

			if test -f "${FOUND[$i]}" || test -d "${FOUND[$i]}"; then
				PRIV=`stat -c "%a" "${FOUND[$i]}"`
			fi

			if test "$1" != "$PRIV" && test "$1" != "0$PRIV"; then
				_sudo "$CMD $1 '${FOUND[$i]}'" 1
			fi
		done
	elif test -f "$2"; then
		PRIV=`stat -c "%a" "$2"`

		if test "$1" != "$PRIV" && test "$1" != "0$PRIV"; then
			_sudo "$CMD $1 '$2'" 1
		fi
	else
		# no stat compare because subdir entry may have changed
		_sudo "$CMD $1 '$2'" 1
	fi
}

