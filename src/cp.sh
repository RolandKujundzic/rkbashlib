#!/bin/bash

#--
# Copy $1 to $2
#
# @param source path
# @param target path
# @param [md5] if set make md5 file comparison
# @global SUDO
# @require _abort _md5 _sudo
#--
function _cp {
	local TARGET=`dirname "$2"`

	local CURR_LOG_NO_ECHO=$LOG_NO_ECHO
	LOG_NO_ECHO=1

	if ! test -d "$TARGET"; then
		_abort "no such directory [$TARGET]"
	fi

	if test "$3" = "md5" && test -f "$1" && test -f "$2"; then
		local MD1=`_md5 "$1"`
		local MD2=`_md5 "$2"`

		if test "$MD1" = "$MD2"; then
			echo "_cp: keep $2 (same as $1)"
		else
			echo "Copy file $1 to $2 (update)"
			_sudo "cp '$1' '$2'" 1
		fi

		return
	fi

	if test -f "$1"; then
		echo "Copy file $1 to $2"
		_sudo "cp '$1' '$2'" 1
	elif test -d "$1"; then
		if test -d "$2"; then
			local PDIR=`dirname $2`"/"
			echo "Copy directory $1 to $PDIR"
			_sudo "cp -r '$1' '$PDIR'" 1
		else
			echo "Copy directory $1 to $2"
			_sudo "cp -r '$1' '$2'" 1
		fi
	else
		_abort "No such file or directory [$1]"
	fi

	LOG_NO_ECHO=$CURR_LOG_NO_ECHO
}

