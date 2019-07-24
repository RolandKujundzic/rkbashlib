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

	local IS_GZIP=`file "$1"  | grep 'gzip compressed data'`

	if test -z "$IS_GZIP"; then
		if test -z "$2"; then
			_abort "invalid gzip file [$1]"
		else 
			echo "$1 is not in gzip format - skip gunzip"
			return
		fi
	fi

	echo "gunzip $1"
	# -f: Fix "Too many levels of symbolic links" error
	gunzip -f "$1"
}

