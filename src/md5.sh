#!/bin/bash

#--
# Print md5sum of file.
#
# @param file
# @require _abort
# @print md5sum
#--
function _md5 {
	if test -z "$1" || ! test -f "$1"
	then
		_abort "No such file [$1]"
	fi

	# use MD5 to drop filename
	local MD5=$(md5sum "$1")

	echo $MD5
}

