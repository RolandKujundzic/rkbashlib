#!/bin/bash

#--
# Append file $2 to file $1 if first 3 lines from $2 are not in $1.
#
# @param target file
# @param source file
# @require _abort _msg
#--
function _append_file {
	local FOUND=
	test -f "$2" || { _abort "no such file [$2]"; return 1; }
	test -s "$1" && FOUND=$(grep "`head -3 \"$2\"`" "$1")
	test -z "$FOUND" || { _msg "$2 was already appended to $1"; return; }

	_msg "append '$2' to '$1'"
	cat "$2" >> "$1" || { _abort "cat '$2' >> '$1'"; return 1; }
}

