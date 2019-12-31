#!/bin/bash

#--
# Overwrite directory $2 with $1 (copy $1 to $2). If backup does not exist
# create it ($2.orig|bak).
#
# @param source directory $1
# @param target directory $2
#--
function _overwrite_dir {
	if ! test -d "$2"; then
		_cp "$1" "$2"
		return
	fi

	local OVERWRITE=1
	local BACKUP="$2.orig"

	if test -d "$2.orig"; then
		OVERWRITE=
		BACKUP="$2.bak"
	fi

	_confirm "Overwrite existing directory $2 (auto-backup)" $OVERWRITE
	if test "$CONFIRM" = "y"; then
		echo "backup and overwrite directory"
		_cp "$2" "$BACKUP"
		_cp "$1" "$2"
	else
		echo "keep existing directory $2"
		return
	fi
}

