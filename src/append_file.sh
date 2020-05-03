#!/bin/bash

#--
# Append file $2 to file $1 if first 3 lines from $2 are not in $1.
#
# @param target file
# @param source file
#--
function _append_file {
	local found h3
	test -f "$2" || _abort "no such file [$2]"
	h3=$(head -3 "$2")

	test -s "$1" && found=$(grep "$h3" "$1")
	test -z "$found" || { _msg "$2 was already appended to $1"; return; }

	_msg "append file '$2' to '$1'"
	cat "$2" >> "$1" || _abort "cat '$2' >> '$1'"
}

