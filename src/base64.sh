#!/bin/bash

#--
# Print base64 of input (or file content if flag == 1).
#
# @param input
# @param optional flag (2^0 = decode, 2^1 = file input)
#--
function _base64 {
	_require_program base64
	test -z "$1" && _abort "Empty parameter"
	local flag

	flag=$(($2 + 0))

	if [[ $((flag & 1)) = 1 ]]; then
		if [[ $((flag & 2)) = 2 ]]; then
			base64 -d "$1"
		else
			echo "$1" | base64 -d
		fi
	elif [[ $((flag & 2)) = 2 ]]; then
		base64 --wrap=0 "$1"
	else
		echo "$1" | base64 --wrap=0
	fi
}

