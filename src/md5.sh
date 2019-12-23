#!/bin/bash

#--
# Print md5sum of file.
#
# @param file
# @require _abort _require_program
# @print md5sum
#--
function _md5 {
	_require_program md5sum
	
	if test -z "$1" || ! test -s "$1"; then
		_abort "No such file [$1]"
	fi

	md5sum "$1" | awk '{print $1}'
}

