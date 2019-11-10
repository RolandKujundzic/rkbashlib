#!/bin/bash

#------------------------------------------------------------------------------
# Backup $1 as $1.orig (if not already done).
#
# @param path
# @require _cp _abort
#------------------------------------------------------------------------------
function _orig {
	if test -f "$1"; then
		if test -f "$1.orig"; then
			echo "Backup $1 as $1.orig"
			_cp "$1" "$1.orig"
		else
			echo "Backup $1.orig already exists"
		fi
	elif test -d "$1"; then
		if test -d "$1.orig"; then
			echo "Backup $1 as $1.orig"
			_cp "$1" "$1.orig"
		else
			echo "Backup $1.orig already exists"
		fi
	else
		_abort "no such file or directory: $1"
	fi
}

