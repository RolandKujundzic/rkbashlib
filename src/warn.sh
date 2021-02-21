#!/bin/bash

#--
# Print warning (red color message to stdout and stderr)
#
# @param message
# @param optional -n
#--
function _warn {
	if test "$2" == '-n'; then
		echo -n -e "\033[0;31m$1\033[0m" 1>&2
	else
		echo -e "\033[0;31m$1\033[0m" 1>&2
	fi
}

