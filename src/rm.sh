#!/bin/bash

#--
# Remove files/directories.
#
# @param path_list
# @param int (optional - abort if set and path is invalid)
# @require _abort _msg
#--
function _rm {
	test -z "$1" && _abort "Empty remove path list"

	local a
	while read a; do
		if ! test -f "$a" && ! test -d "$a"; then
			test -z "$2" || _abort "No such file or directory '$a'"
		else
			_msg "remove '$a'"
			rm -rf "$a" || _abort "rm -rf '$a'"
		fi
	done <<< `echo -e "$1"`
}

