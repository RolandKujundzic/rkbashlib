#!/bin/bash

#--
# Ask question. Skip default answer with SPACE. Loop max. 3 times
# until answered if $3=1. Use _ASK_DEFAULT=aK if answer selection 
# <a1|...|an> is used.
#
# @param string label
# @param default answer or answer selection
# @param bool required 1|[] (default empty)
# @global _ASK_DEFAULT
# @export ANSWER
#--
function _ask {
	local default
	local allow
	local label
	
	if test -z "$2"; then
		label="$1  "
	elif [[ "${2:0:1}" == "<" && "${2: -1}" == ">" ]]; then
		label="$1  $2  "
 		allow="|${2:1: -1}|"

		if ! test -z "$_ASK_DEFAULT"; then
			default="$_ASK_DEFAULT"
			label="$label [$default]"
			_ASK_DEFAULT=
		fi
	else 
		label="$1  [$2]  "
 		default="$2"
	fi

	echo -n "$label"
	read

	if test "$REPLY" = " "; then
		ANSWER=
	elif [[ -z "$REPLY" && ! -z "$default" ]]; then
		ANSWER="$default"
	elif ! test -z "$allow"; then
		[[ "$allow" == *"|$REPLY|"* ]] && ANSWER="$REPLY" || ANSWER=
	else
		ANSWER="$REPLY"
	fi

	if test -z "$ANSWER" && test "$3" -gt 0; then
		test "$3" -ge 3 && _abort "you failed to answer the question 3 times"
		local RECURSION=$(($3 + 1))
		_ask "$1" "$2" "$RECURSION"
	fi
}
