#!/bin/bash

#------------------------------------------------------------------------------
# Create LICENCSE file for "gpl-3.0".
#
# @see https://help.github.com/en/articles/licensing-a-repository 
# @param license name (default "gpl-3.0")
# @require _abort _wget
#------------------------------------------------------------------------------
function _license {
	if test -z "$1" || test "$1" = "gpl-3.0"; then
		_wget "http://www.gnu.org/licenses/gpl-3.0.txt" "LICENSE"
	else
		_abort "unknown license [$1] use [gpl-3.0]"
	fi
}
