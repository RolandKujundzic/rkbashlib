#!/bin/bash

#--
# Remove file or directory.
#
# @param path/to/entry
# @param int (optional - abort if set and path is invalid)
# @require _abort _msg
#--
function _rm {
	test -z "$1" && _abort "Empty remove path"

	if ! test -f "$1" && ! test -d "$1"; then
		test -z "$2" || _abort "No such file or directory '$1'"
	else
		_msg "remove '$1'"
		rm -rf "$1" || _abort "rm -rf '$1'"
	fi
}

