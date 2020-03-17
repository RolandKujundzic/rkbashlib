#!/bin/bash

#--
# Ask question.
#
# @export ANSWER
# @param string label
# @param default answer
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
}
