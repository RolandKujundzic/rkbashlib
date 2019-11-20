#!/bin/bash

#------------------------------------------------------------------------------
# Abort if user is not root. If sudo cache time is ok allow sudo with $1 = 1.
#
# @param try sudo
# @require _abort
#------------------------------------------------------------------------------
function _run_as_root {
	test "$UID" = "0" && return

	if test -z "$1"; then
		_abort "Please change into root and try again"
	else
		echo "sudo true - Please type in your password"
		sudo true 2>/dev/null || _abort "sudo true failed - Please change into root and try again"
	fi
}

