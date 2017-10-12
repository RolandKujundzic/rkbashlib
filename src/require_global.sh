#!/bin/bash

#------------------------------------------------------------------------------
# Abort if global variable is empty.
#
# @param variable name
# @require _abort
#------------------------------------------------------------------------------
function _require_global {
	local a=; for a in $1; do
		if test -z "${!a}"; then
			_abort "No such global variable $a"
		fi
	done
}
