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
# @global ASK_DEFAULT ASK_DESC
# @export ANSWER
#--
function _ask {
	local allow default msg label recursion
	
	if test -z "$2"; then
		:
	elif [[ "${2:0:1}" == "<" && "${2: -1}" == ">" ]]; then
		label="$2  "
 		allow="|${2:1: -1}|"

		if test -n "$ASK_DEFAULT"; then
			default="$ASK_DEFAULT"
			label="$label [$default]  "
			ASK_DEFAULT=
		fi
	else 
		label="[$2]  "
 		default="$2"
	fi
	
	if [[ "$AUTOCONFIRM" = "default" && -n "$default" ]]; then
		ANSWER="$default"
		AUTOCONFIRM=
		return
	fi

	msg="\033[0;35m$1\033[0m"
	if test -z "$ASK_DESC"; then
		echo -en "$msg  $label"
	else
		echo -en "$msg\n\n$ASK_DESC\n\n$label"
	fi

	ASK_DESC=
	read -r

	if test "$REPLY" = " "; then
		ANSWER=
	elif [[ -z "$REPLY" && -n "$default" ]]; then
		ANSWER="$default"
	elif test -n "$allow"; then
		[[ "$allow" == *"|$REPLY|"* ]] && ANSWER="$REPLY" || ANSWER=
	else
		ANSWER="$REPLY"
	fi

	recursion="${4:-0}"
	if test -z "$ANSWER" && test "$recursion" -lt 3; then
		test "$recursion" -ge 2 && _abort "you failed to answer the question 3 times"
		recursion=$((recursion + 1))
		_ask "$1" "$2" "$3" "$recursion"
	fi

	[[ -z "$ANSWER" && "$1" = '1' ]] && _abort "you failed to answer the question"
}

