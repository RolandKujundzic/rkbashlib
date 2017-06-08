#!/bin/bash

#------------------------------------------------------------------------------
# Abort if user is not root.
#
# @require abort
#------------------------------------------------------------------------------
function _run_as_root {
	if test -z "$UID" != "0"
	then
		_abort "Please change into root and try again"
	fi
}

