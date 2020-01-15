#!/bin/bash

#--
# Print random string of length $1
#
# @param string length (default = 8)
#--
function _random_string {
	local CHARS="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_"
	local LEN=${1:-8}
	local i

	for (( i = 0; i < $1; i++ )); do
		echo -n "${CHARS:RANDOM%${#CHARS}:1}"
	done
	echo
}

