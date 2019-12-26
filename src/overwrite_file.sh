#!/bin/bash

#--
# Overwrite file $2 with $1 (copy $1 to $2). If backup does not exist
# create it ($2.orig|bak).
#
# @param source file $1
# @param target file $2
#--
function _overwrite_file {
	if ! test -f "$2"; then
		_cp "$1" "$2"
		return
	fi

	local OVERWRITE=1
	local BACKUP="$2.orig"

	if test -f "$2.orig"; then
		OVERWRITE=
		BACKUP="$2.bak"
	fi

	_confirm "Overwrite existing file $2 (auto-backup)" $OVERWRITE
	if test "$CONFIRM" = "y";
		echo "backup and overwrite file"
		_cp "$2" "$2.bak" md5
		_cp "$1" "$2" md5
	else
		echo "keep existing file $2"
		return
	fi
}

