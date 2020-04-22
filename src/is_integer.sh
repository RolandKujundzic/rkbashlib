#!/bin/bash

#--
# Abort if parameter is not integer
#
# @param number
#--
function _is_integer {
	local re='^[0-9]+$'

	if ! [[ $1 =~ $re ]] ; then
		_abort "[$1] is not integer"
	fi
}

