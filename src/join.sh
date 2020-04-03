#!/bin/bash

#--
# Join parameter ($2 or shift; echo "$*") with first parameter as delimiter ($1).
# If parameter count is 2 try if $2 is array.
#
# @example _join ';' 'a' 'x y' 83
# @example K=( a 'x y' 83); _join ';' K
#
# @param delimiter
# @param array|array parts 
# @echo 
#--
function _join {
	local IFS="$1"
	local OUT=""

	if test $# -eq 2; then
		if test "$2" != '_' && local -n array=$2 2>/dev/null; then
			OUT="${array[0]}"
			local i
			for (( i=1; i < ${#array[@]}; i++ )); do
				OUT="$OUT$1${array[i]}"
			done
		else
			OUT="${*:2}"
		fi
	else
  	OUT="${*:2}"
	fi

	echo "$OUT"
}

