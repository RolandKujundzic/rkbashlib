#!/bin/bash

#--
# Backup $1 as $1.orig (if not already done).
#
# @param path
# @param bool do not abort if $1 is missing (optional, default = 0 = abort)
#--
function _orig {
	if ! test -f "$1" && ! test -d "$1"; then
		test -z "$2" && _abort "missing $1"
		return 1
	fi

	local RET=0

	if test -f "$1.orig"; then
		_msg "$1.orig already exists"
		RET=1
	else
		_msg "create backup $1.orig"
		_cp "$1" "$1.orig"
	fi

	return $RET
}

