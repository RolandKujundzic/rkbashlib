#!/bin/bash

#--
# Append $2 to $1 if first 3 lines from $2 are not in $1
#
# @param target file
# @param source file
# @require _abort
#--
function _append {
	local FOUND=$(grep "`head -3 \"$2\"`" "$1")
	test -z "$FOUND" || { echo "$2 was already appended to $1"; return; }

	echo "append '$2' to '$1'"
	cat "$2" >> "$1" || _abort "cat '$2' >> '$1'"
}

