#!/bin/bash

#--
# Print md5sum of file (text if $2=1).
#
# @param file
# @param bool (optional: 1 = threat $1 as string)
# @require _abort _require_program
# @print md5sum
#--
function _md5 {
	_require_program md5sum
	
	if test -z "$1"; then
		_abort "Empty parameter"
	elif test -f "$1"; then
		md5sum "$1" | awk '{print $1}'
	elif test "$2" = "1"; then
		echo -n "$1" | md5sum | awk '{print $1}'
	else
		_abort "No such file [$1]"
	fi
}

