#!/bin/bash

#--
# Append text $2 to file $1 if not found in $1.
#
# @param target file
# @param text
# @require _abort _msg _mkdir
#--
function _append_txt {
	local found
	test -f "$1" && found=$(grep "$2" "$1")
	test -z "$found" || { _msg "$2 was already appended to $1"; return; }

	local dir=`dirname "$1"`
	test -d "$dir" || _mkdir "$dir"

	_msg "append text '$2' to '$1'"
	if ! test -f "$1" || test -w "$1"; then
		echo "append [$2] to [$1]"
		echo "$2" >> "$1" || _abort "echo '$2' >> '$1'"
	else
		echo "sudo append [$2] to [$1]"
		{ echo "$2" | sudo tee -a "$1" >/dev/null; } || _abort "echo '$2' | sudo tee -a '$1'"
	fi
}

