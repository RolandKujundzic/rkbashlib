#!/bin/bash

#--
# Abort if program (function) does not exist
#
# @param program
# @param flag (default = 0, 1: return 1 if not found)
# @require _abort
# @return bool (if $2==1)
#--
function _require_program {
	local TYPE=`type -t "$1"`
	local ERROR=0

	test "$TYPE" = "function" && return $ERROR

	command -v "$1" >/dev/null 2>&1 || ERROR=1

	if test -z "$2" && ! test -z "$ERROR"; then
		_abort "No such program [$1]"
	fi

	return $ERROR
}

