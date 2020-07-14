#!/bin/bash

#--
# Print message
#
# @param message
# @param echo option (-n|-e|default='')
#--
function _msg {
	if test -z "$2"; then
		echo "$1"
	else
		echo "$2" "$1"
	fi
}

