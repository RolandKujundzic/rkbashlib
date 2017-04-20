#!/bin/bash

#------------------------------------------------------------------------------
# Change to directory $1. If parameter is empty and _cd was executed before 
# change to last directory.
#
# @param path
# @export LAST_DIR
# @require abort
#------------------------------------------------------------------------------
function _cd {
	echo "cd '$1'"

	if test -z "$1"
	then
		if ! test -z "$LAST_DIR"
		then
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

