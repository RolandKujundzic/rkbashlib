#!/bin/bash

declare -A ARG
declare ARGV

#--
# Set ARG[name]=value if --name=value or name=value.
# If --name set ARG[name]=1. Set ARG[0], ARG[1], ... (num = ARG[#]) otherwise.
# (Re)Set ARGV=( $@ ). Don't reset ARG (allow default).
# Use _parse_arg "$@" to preserve whitespace.
#
# @param "$@"
# @export ARG (hash)
#--
function _parse_arg {
	ARGV=()

	local n=0; local i; local key; local val;
	for (( i = 0; i <= $#; i++ )); do
		ARGV[$i]="${!i}"
		val="${!i}"
		key=

		if [[ $val == "--"*"="* ]]; then
			key="${val/=*/}"
			key="${key/--/}"
			val="${val#*=}"
		elif [[ $val == "--"* ]]; then
			key="${val/--/}"
			val=1
		elif [[ $val == *"="* ]]; then
			key="${val/=*/}"
			val="${val#*=}"
		fi

		if test -z "$key"; then
			ARG[$n]="$val"
			n=$(( n + 1 ))
		else
			ARG[$key]="$val"
		fi
	done

	ARG[#]=$n
}

