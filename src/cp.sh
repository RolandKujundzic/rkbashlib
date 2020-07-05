#!/bin/bash

#--
# Copy $1 to $2
#
# @param source path
# @param target path
# @param [md5] if set make md5 file comparison
# @export CP_KEEP=1 if $3=md5 and target exists and is same as source
# export CP_FIRST=1 if $3=md5 and target does not exist
# @global SUDO
# shellcheck disable=SC2034
#--
function _cp {
	local curr_lno target_dir md1 md2 pdir
	curr_lno="$LOG_NO_ECHO"
	LOG_NO_ECHO=1

	CP_FIRST=
	CP_KEEP=

	test -z "$2" && _abort "empty target"

	target_dir=$(dirname "$2")
	test -d "$target_dir" || _abort "no such directory [$target_dir]"

	if test "$3" != 'md5'; then
		:
	elif ! test -f "$2"; then
		CP_FIRST=1
	elif test -f "$1"; then
		md1=$(_md5 "$1")
		md2=$(_md5 "$2")

		if test "$md1" = "$md2"; then
			_msg "_cp: keep $2 (same as $1)"
			CP_KEEP=1
		else
			_msg "Copy file $1 to $2 (update)"
			_sudo "cp '$1' '$2'" 1
		fi

		return
	fi

	if test -f "$1"; then
		_msg "Copy file $1 to $2"
		_sudo "cp '$1' '$2'" 1
	elif test -d "$1"; then
		if test -d "$2"; then
			pdir="$2"
			_confirm "Remove existing target directory '$2'?"
			if test "$CONFIRM" = "y"; then
				_rm "$pdir"
				_msg "Copy directory $1 to $2"
				_sudo "cp -r '$1' '$2'" 1
			else
				_msg "Copy directory $1 to $2 (use rsync)" 
				_rsync "$1/" "$2"
			fi
		else
			_msg "Copy directory $1 to $2"
			_sudo "cp -r '$1' '$2'" 1
		fi
	else
		_abort "No such file or directory [$1]"
	fi

	LOG_NO_ECHO="$curr_lno"
}

