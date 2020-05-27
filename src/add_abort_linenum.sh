#!/bin/bash

#--
# Add linenumber to $1 after _abort if caller function does not exist.
#
# @param string file 
# @global RKBASH_DIR
#--
function _add_abort_linenum {
	local lines changes tmp_file fix_line
	type -t caller >/dev/null 2>/dev/null && return

	_mkdir "$RKBASH_DIR/add_abort_linenum" >/dev/null
	tmp_file="$RKBASH_DIR/add_abort_linenum/"$(basename "$1")
	test -f "$tmp_file" && _abort "$tmp_file already exists"

	echo -n "add line number to _abort in $1"
	changes=0

	readarray -t lines < "$1"
	for ((i = 0; i < ${#lines[@]}; i++)); do
		fix_line=$(echo "${lines[$i]}" | grep -E -e '(;| \|\|| &&) _abort ["'"']" -e '^\s*_abort ["'"']" | grep -vE -e '^\s*#' -e '^\s*function ')
		if test -z "$fix_line"; then
			echo "${lines[$i]}" >> "$tmp_file"
		else
			changes=$((changes+1))
			echo "${lines[$i]}" | sed -E 's/^(.*)_abort (.+)$/\1_abort '$((i+1))' \2/g' >> "$tmp_file"
		fi
	done

	echo " ($changes)"
	_cp "$tmp_file" "$1" >/dev/null
}

