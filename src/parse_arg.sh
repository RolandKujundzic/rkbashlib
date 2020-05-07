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
# @export ARG (hash) ARGV (array)
# shellcheck disable=SC2034
#--
function _parse_arg {
	ARGV=()

	local i n key val
	n=0
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
		elif test -z "${ARG[$key]}"; then
			ARG[$key]="$val"
		else
			ARG[$key]="${ARG[$key]} $val"
		fi
	done

	ARG[#]=$n
}

