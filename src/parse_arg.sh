#!/bin/bash

declare -A ARG
declare ARGV

#--
# Set ARG[name]=value if --name=value, -name=value or 
# name=value (name = ^[a-zA-Z0-9_\.\-]+). If --name set ARG[name]=1. 
# Set ARG[0], ARG[1], ... (num = ARG[#]) otherwise.
# Set ARGV=( $@ ). Don't reset ARG (allow default).
# Skip if ${#ARGV[@]} -gt 0.
# 
# @example _parse_arg "$@"
# @param "$@"
# @export ARG (hash) ARGV (array)
# shellcheck disable=SC2034,SC1001
#--
function _parse_arg {
	test "${#ARG[@]}" -gt 0 && return
	ARGV=()

	local i n key val
	n=0
	for (( i = 0; i <= $#; i++ )); do
		ARGV[$i]="${!i}"
		val="${!i}"
		key=

		if [[ "$val" =~ ^\-?\-?[a-zA-Z0-9_\.\-]+= ]]; then
			key="${val/=*/}"
			val="${val#*=}"
			test "${key:0:2}" = '--' && key="${key:2}"
			test "${key:0:1}" = '-' && key="${key:1}"
		elif [[ "$val" =~ ^\-\-[[a-zA-Z0-9_\.\-]+$ ]]; then
			key="${val:2}"
			val=1
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

