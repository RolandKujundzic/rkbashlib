#!/bin/bash

#------------------------------------------------------------------------------
# Remove files/directories.
#
# @param path_list
# @param int (optional - abort if set and path is invalid)
# @require abort
#------------------------------------------------------------------------------
function _rm {

	if test -z "$1"; then
		_abort "Empty remove path list"
	fi

	for a in $1
	do
		if ! test -f $a && ! test -d $a
		then
			if ! test -z "$2"; then
				_abort "No such file or directory $a"
			fi
		else
			echo "remove $a"
			rm -rf $a
		fi
	done
}

