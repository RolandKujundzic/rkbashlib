#!/bin/bash

#------------------------------------------------------------------------------
# Return linux, macos, cygwin.
#
# @print string
#------------------------------------------------------------------------------
function _os_type {
	if test "$OSTYPE" = "linux-gnu"; then
		echo "linux"
	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
		echo "linux"
	elif [ "$(uname)" == "Darwin" ]; then
		echo "macos"        
	elif [ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]; then
		echo "cygwin"
	fi
}
