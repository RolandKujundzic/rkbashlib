#!/bin/bash

#------------------------------------------------------------------------------
# Abort if file or directory privileges don't match.
#
# @param path
# @param privileges (e.g. 600)
# @require _abort
#------------------------------------------------------------------------------
function _require_priv {
	if test -z "$2"; then
		_abort "empty privileges"
	fi

	local priv=`stat -c '%a' "$1" || _abort "no such filesystem entry '$1'"`

	if ! test "$2" = "$priv"; then
		_abort "invalid privileges - chmod $1 '$2'"
	fi
}

