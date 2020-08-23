#!/bin/bash

#--
# Print message
#
# @param message
# @param optional -n
#--
function _msg {
	if test "$2" == '-n'; then
		echo -n -e "\033[0;2m$1\033[0m"
	else
		echo -e "\033[0;2m$1\033[0m"
	fi
}

