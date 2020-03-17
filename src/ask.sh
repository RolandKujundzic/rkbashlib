#!/bin/bash

#--
# Ask question. Skip default answer with SPACE. Loop max. 3 times
# until answered if $3=1. 
#
# @param string label
# @param default answer
# @param bool required 1|[] (default empty)
# @export ANSWER
# @required _abort
#--
function _ask {
	local LABEL="$1  "
	test -z "$2" || LABEL="$1  [$2]  "

	echo -n "$LABEL"
	read

	if test "$REPLY" = " "; then
		ANSWER=
	elif test -z "$REPLY" && ! test -z "$2"; then
		ANSWER="$2"
	else
		ANSWER="$REPLY"
	fi

	if test -z "$ANSWER" && test "$3" -gt 0; then
		test "$3" -ge 3 && _abort "you failed to answer the question 3 times"
		local RECURSION=$(($3 + 1))
		_ask "$1" "$2" "$RECURSION"
	fi
}
