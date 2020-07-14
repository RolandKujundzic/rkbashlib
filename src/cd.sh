#!/bin/bash

#--
# Change to directory $1. If parameter is empty and _cd was executed before 
# change to last directory.
#
# @param path
# @param do_not_echo
# @export LAST_DIR
#--
function _cd {
	local has_realpath curr_dir goto_dir
	has_realpath=$(command -v realpath)

	if [[ -n "$has_realpath" && -n "$1" ]]; then
		curr_dir=$(realpath "$PWD")
		goto_dir=$(realpath "$1")

		if test "$curr_dir" = "$goto_dir"; then
			return
		fi
	fi

	if test -z "$2"; then
		echo "cd '$1'"
	fi

	if test -z "$1"; then
		if test -n "$LAST_DIR"; then
			_cd "$LAST_DIR"
			return
		else
			_abort "empty directory path"
		fi
	fi

	if ! test -d "$1"; then
		_abort "no such directory [$1]"
	fi

	LAST_DIR="$PWD"

	cd "$1" || _abort "cd '$1' failed"
}

