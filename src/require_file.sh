#!/bin/bash

#------------------------------------------------------------------------------
# Abort if file does not exists or owner or privileges don't match.
#
# @param file path
# @param file owner[:group] (optional)
# @param file privileges (optional, e.g. 600)
# @require _abort
#------------------------------------------------------------------------------
function _require_file {
	test -f "$1" || _abort "no such file '$1'"

	if ! test -z "$2"; then
		local arr=( ${2//:/ } )
		local owner=`stat -c '%U' "$1"`
		local group=`stat -c '%G' "$1"`

		if ! test -z "${arr[0]}" && ! test "${arr[0]}" = "$owner"; then
			_abort "invalid owner - chown ${arr[0]} '$1'"
		fi

		if ! test -z "${arr[1]}" && ! test "${arr[1]}" = "$group"; then
			_abort "invalid group - chgrp ${arr[1]} '$1'"
		fi
	fi

	if ! test -z "$3"; then
		local priv=`stat -c '%a' "$1"`

		if ! test "$3" = "$priv"; then
			_abort "invalid privileges - chmod $3 '$1'"
		fi
	fi
}

