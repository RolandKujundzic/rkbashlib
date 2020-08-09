#!/bin/bash

#--
# @example x="Error\nInfo" && echo -e "$(_warn_msg $x)"
# @param multiline
# @return multiline with first line in red
#--
function _warn_msg {
	local msg="$1"
	shift
	echo '\033[0;31m'"$msg"'\033[0m'
	echo "$*"
}

