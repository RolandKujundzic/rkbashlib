#!/bin/bash

#------------------------------------------------------------------------------
# Move files/directories. Target path directory must exist.
#
# @param source_path
# @param target_path
# @require abort
#------------------------------------------------------------------------------
function _mv {

	if test -z "$1"; then
		_abort "Empty source path"
	fi

	if test -z "$2"; then
		_abort "Empty target path"
	fi

	local PDIR=`dirname "$2"`
	if ! test -d "$PDIR"; then
		_abort "No such directory [$PDIR]"
	fi

	local AFTER_LAST_SLASH=${1##*/}

	if test "$AFTER_LAST_SLASH" = "*"
	then
		echo "mv $1 $2"
		mv $1 $2 || _abort "mv $1 $2 failed"
	else
		echo "mv '$1' '$2'"
		mv "$1" "$2" || _abort "mv '$1' '$2' failed"
	fi
}

