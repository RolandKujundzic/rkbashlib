#!/bin/bash

#------------------------------------------------------------------------------
# Print md5sum of file.
#
# @param file
# @require _abort
# @print md5sum
#------------------------------------------------------------------------------
function _md5 {

	if test -z "$1" || ! test -f "$1"
	then
		_abort "No such file [$1]"
	fi

	local has_md5=`which md5`
	local md5=

	if test -z "$has_md5"
	then
		# on Linux
		md5=($(md5sum "$1"))
	else
		# on OSX
		md5=`md5 -q "$1"`
	fi

	echo $md5
}

