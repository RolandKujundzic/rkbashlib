#!/bin/bash

#--
# Replace text in file or append text to file.
# Ask (default = y) and backup first. 
# For replace use s/orig/replace/ or s#orig#replace#g 
# otherwise $1 will be appended to $2.
#
# @param sed replace expression (-E) or append text
# @param file
#--
function _update_file {
	_require_file "$2"

	if [[ "${1:0:1}" = 's' && ( "${1:1:1}" = '/'  || "${1:1:1}" = '#' ) ]]; then
		_confirm "Apply replace $1\nto $2" 1
		if test "$CONFIRM" = 'y'; then
			_backup_file "$2"
			sed -i -E "$1" "$2"
		fi
	else
		_confirm "Append '$2'\nto $2" 1
		if test "$CONFIRM" = 'y'; then
			_backup_file "$2"
			echo "$1" >> "$2"
		fi
	fi
}
