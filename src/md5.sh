#!/bin/bash

#------------------------------------------------------------------------------
# Print md5sum of file.
#
# @param file
# @require _abort _require_program
# @print md5sum
#------------------------------------------------------------------------------
function _md5 {

	if test -z "$1" || ! test -f "$1"
	then
		_abort "No such file [$1]"
	fi

	_require_program md5
	local md5=

	if test -z "$HAS_PROGRAM"
	then
		# on Linux
		_require_program md5sum 1		
		md5=($(md5sum "$1"))
	else
		# on OSX
		md5=`md5 -q "$1"`
	fi

	echo $md5
}

