#!/bin/bash

#--
# Join parameter ($2 or shift; echo "$*") with first parameter as delimiter ($1).
# If parameter count is 2 try if $2 is array.
#
# @beware no whitespace allowed, only single char delimiter 
#
# @example _join ';' 'a' 'x y' 83
# @example K=( a 'x y' 83); _join ';' K
#
# @param delimiter
# @param array|array parts 
# @echo 
#--
function _join {
	local out IFS

	IFS="$1"

	if test $# -eq 2; then
		if test "$2" != '_' && local -n array=$2 2>/dev/null; then
			out="${array[0]}"
			local i
			for (( i=1; i < ${#array[@]}; i++ )); do
				out="$out$1${array[i]}"
			done
		else
			out="${*:2}"
		fi
	else
  	out="${*:2}"
	fi

	echo "$out"
}

