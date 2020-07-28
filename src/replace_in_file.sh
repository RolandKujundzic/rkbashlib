#!/bin/bash

#--
# Replace text in file. Backup file.
#
# @param sed replace expression (-E)
# @param file
#--
function _replace_in_file {
	_require_file "$2"
	_confirm "Apply replace $1\nto $2" 1
	if test "$CONFIRM" = 'y'; then
		_backup_file "$2"
		sed -i -E "$1" "$2"
	fi
}
