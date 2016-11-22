#!/bin/bash

#------------------------------------------------------------------------------
# Abort if global variable is empty.
#
# @param variable name
# @require abort
#------------------------------------------------------------------------------
function _require_global {
	if test -z "${!1}"; then
		_abort "No such global variable [$1]"
	fi
}
