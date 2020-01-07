#!/bin/bash

#--
# Append text $2 to file $1 if not found in $1.
#
# @param target file
# @param text
# @require _abort
#--
function _append_txt {
	local FOUND=
	test -f "$1" && FOUND=$(grep "$2" "$1")
	test -z "$FOUND" || { _msg "$2 was already appended to $1"; return; }

	_msg "append text '$2' to '$1'"
	echo "$2" >> "$1" || _abort "echo '$2' >> '$1'"
}

