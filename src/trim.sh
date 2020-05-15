#!/bin/bash

#--
# Print trimmed string. 
#
# @param string name (use /dev/stdin if not set)
# shellcheck disable=SC2120
#--
function _trim {
	local input
	test -z "${1+x}" && input=$(cat /dev/stdin) || input="$1"
	echo -e "$input" | sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//'
}
