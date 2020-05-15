#!/bin/bash

#--
# Print random string of length $1 (chars from [0-9a-zA-Z-_]).
# 
# @example _random_string n 10 26 = random from [a-z], length n
# @example _random_string n 36 26 = random from [A-Z], length n
# @example _random_string n 0 62 = random from [0-9a-zA-Z], length n 
#
# @param string length (default = 8)
# @param string char pos [0-63]
# @param string char length [1-64]
#--
function _random_string {
	local i len chars
	chars="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_"
	len=${1:-8}

	if ! test -z "$2" && ! test -z "$3"; then
		chars="${chars:$2:$3}"
	fi

	for (( i = 0; i < len; i++ )); do
		echo -n "${chars:RANDOM%${#chars}:1}"
	done
	echo
}

