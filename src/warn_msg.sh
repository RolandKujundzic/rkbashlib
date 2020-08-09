#!/bin/bash

#--
# @example x="Error\nInfo" && echo -e "$(_warn_msg "$x")"
# @param multiline
# @return multiline with first line in red
#--
function _warn_msg {
	local line first
	while IFS= read -r line; do
		if test "$first" = '1'; then
			echo "$line"
		else
			echo '\033[0;31m'"$line"'\033[0m'
			first=1
		fi
	done <<< "$@"
}

