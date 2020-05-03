#!/bin/bash

#--
# Ask question. Skip default answer with SPACE. Loop max. 3 times
# until answered if $3=1. Use ASK_DEFAULT=aK if answer selection 
# <a1|...|an> is used. Use AUTOCONFIRM=default to skip question
# if default answer is provided.
#
# @param string label
# @param default answer or answer selection
# @param bool required 1|[] (default empty)
# @global ASK_DEFAULT
# @export ANSWER
#--
function _ask {
	local allow default label recursion
	
	if test -z "$2"; then
		label="$1  "
	elif [[ "${2:0:1}" == "<" && "${2: -1}" == ">" ]]; then
		label="$1  $2  "
 		allow="|${2:1: -1}|"

		if ! test -z "$ASK_DEFAULT"; then
			default="$ASK_DEFAULT"
			label="$label [$default]"
			ASK_DEFAULT=
		fi
	else 
		label="$1  [$2]  "
 		default="$2"
	fi
	
	if test "$AUTOCONFIRM" = "default" && ! test -z "$default"; then
		ANSWER="$default"
		AUTOCONFIRM=
		return
	fi

	echo -n "$label"
	read -r

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
		local recursion=$(($3 + 1))
		_ask "$1" "$2" "$recursion"
	fi
}

