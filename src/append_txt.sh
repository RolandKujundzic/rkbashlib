#!/bin/bash

#--
# Append text $2 to file $1 if not found in $1.
#
# @param target file
# @param text
# @require _abort _msg _mkdir
#--
function _append_txt {
	local FOUND=
	test -f "$1" && FOUND=$(grep "$2" "$1")
	test -z "$FOUND" || { _msg "$2 was already appended to $1"; return; }

	local DIR=`dirname "$1"`
	test -d "$DIR" || _mkdir "$DIR"

	_msg "append text '$2' to '$1'"
	if test -w "$1"; then
		echo "$2" >> "$1" || _abort "echo '$2' >> '$1'"
	else
		{ echo "$2" | sudo tee -a "$1" >/dev/null; } || _abort "echo '$2' | sudo tee -a '$1'"
	fi
}

