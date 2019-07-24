#!/bin/bash

#------------------------------------------------------------------------------
# Gunzip file.
#
# @param file
# @param ignore_if_not_gzip (optional)
# @require _abort
#------------------------------------------------------------------------------
function _gunzip {

	if ! test -f "$1"; then
		_abort "no such gzip file [$1]"
	fi

	local REAL_FILE=`realpath "$1"`
	local IS_GZIP=`file "$REAL_FILE"  | grep 'gzip compressed data'`

	if test -z "$IS_GZIP"; then
		if test -z "$2"; then
			_abort "invalid gzip file [$1]"
		else 
			echo "$1 is not in gzip format - skip gunzip"
			return
		fi
	fi

	local TARGET=`echo "$1" | sed -e 's/\.gz$//'`

	if test -L "$1"; then
		echo "gunzip -c '$1' > '$TARGET'"
		gunzip -c "$1" > "$TARGET"
	else
		echo "gunzip $1"
		gunzip "$1"
	fi

	if ! test -f "$TARGET"; then
		_abort "gunzip failed - no such file $TARGET"
	fi
}

