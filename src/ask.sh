#!/bin/bash

#--
# Ask question.
#
# @param string label
# @param default answer
#--
function _ask {
	local LABEL="$1  "
	test -z "$2" || LABEL="$1  [$2]  "

	echo -n "$LABEL"
	read ANSWER

	if test -z "$ANSWER" && ! test -z "$2"; then
		ANSWER="$2"
	fi
}
