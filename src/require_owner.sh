#!/bin/bash

#--
# Abort if file or directory owner:group don't match.
#
# @param path
# @param owner[:group]
#--
function _require_owner {
	if ! test -f "$1" && ! test -d "$1"; then
		_abort "no such file or directory '$1'"
	fi

	local arr=( ${2//:/ } )
	local owner=`stat -c '%U' "$1" 2>/dev/null`
	test -z "$owner" && _abort "stat -c '%U' '$1'"
	local group=`stat -c '%G' "$1" 2>/dev/null`
	test -z "$group" && _abort "stat -c '%G' '$1'"

	if ! test -z "${arr[0]}" && ! test "${arr[0]}" = "$owner"; then
		_abort "invalid owner - chown ${arr[0]} '$1'"
	fi

	if ! test -z "${arr[1]}" && ! test "${arr[1]}" = "$group"; then
		_abort "invalid group - chgrp ${arr[1]} '$1'"
	fi
}

