#!/bin/bash

#--
# Change mode of path $2 to $1. If chmod failed try sudo.
# Use _find first to chmod all FOUND entries.
#
# @param file mode (octal)
# @param file path (if path is empty use $FOUND)
# global CHMOD (default chmod -R)
# shellcheck disable=SC2006
#--
function _chmod {
	local tmp cmd i priv
	test -z "$1" && _abort "empty privileges parameter"
	test -z "$2" && _abort "empty path"

	tmp=$(echo "$1" | sed -E 's/[012345678]*//')
	test -z "$tmp" || _abort "invalid octal privileges '$1'"

	cmd="chmod -R"
	if ! test -z "$CHMOD"; then
		cmd="$CHMOD"
		CHMOD=
	fi

	if test -z "$2"; then
		for ((i = 0; i < ${#FOUND[@]}; i++)); do
			priv=

			if test -f "${FOUND[$i]}" || test -d "${FOUND[$i]}"; then
				priv=`stat -c "%a" "${FOUND[$i]}"`
			fi

			if test "$1" != "$priv" && test "$1" != "0$priv"; then
				_sudo "$cmd $1 '${FOUND[$i]}'" 1
			fi
		done
	elif test -f "$2"; then
		priv=`stat -c "%a" "$2"`

		if [[ "$1" != "$priv" && "$1" != "0$priv" ]]; then
			_sudo "$cmd $1 '$2'" 1
		fi
	elif test -d "$2"; then
		# no stat compare because subdir entry may have changed
		_sudo "$cmd $1 '$2'" 1
	fi
}

