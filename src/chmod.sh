#!/bin/bash

#------------------------------------------------------------------------------
# Change mode of file $2 to $1. If chmod failed try sudo.
#
# @param file mode (octal)
# @param file path
# @require _abort _sudo
#------------------------------------------------------------------------------
function _chmod {

	if ! test -f "$2" && ! test -d "$2"; then
		_abort "no such file or directory [$2]"
	fi

	if test -z "$1"; then
		_abort "empty privileges parameter"
	fi

	local tmp=`echo "$1" | sed -e 's/[012345678]*//'`
	
	if ! test -z "$tmp"; then
		_abort "invalid octal privileges '$1'"
	fi

	local PRIV=`stat -c "%a" "$2"`

	if test "$1" = "$PRIV" || test "$1" = "0$PRIV"; then
		echo "keep existing mode $1 of $2"
		return
	fi

	_sudo "chmod -R $1 '$2'"
}

