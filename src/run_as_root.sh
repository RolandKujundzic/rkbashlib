#!/bin/bash

#------------------------------------------------------------------------------
# Abort if user is not root.
#
# @require _abort
#------------------------------------------------------------------------------
function _run_as_root {
	if test "$UID" != "0"; then
		echo "sudo true - Please type in your password"
		sudo true 2>/dev/null || _abort "sudo true failed - Please change into root and try again"
	fi
}

