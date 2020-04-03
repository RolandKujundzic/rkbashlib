#!/bin/bash

#--
# Add linenumber to $1 after _abort if caller function does not exist.
#
# @param string file 
# @require _cp _mkdir _abort
#--
function _add_abort_linenum {
	type -t caller >/dev/null 2>/dev/null && return

	local LINES
	local NEW_LINE

	_mkdir "$RKSCRIPT_DIR/add_abort_linenum" >/dev/null
	local TMP_FILE="$RKSCRIPT_DIR/add_abort_linenum/"`basename "$1"`
	test -f "$TMP_FILE" && _abort "$TMP_FILE already exists"

	echo -n "add line number to _abort in $1"
	local CHANGES=0

	readarray -t LINES < "$1"
	for ((i = 0; i < ${#LINES[@]}; i++)); do
		FIX_LINE=`echo "${LINES[$i]}" | grep -E -e '(;| \|\|| &&) _abort ["'"']" -e '^\s*_abort ["'"']" | grep -vE -e '^\s*#' -e '^\s*function '`
		test -z "$FIX_LINE" && echo "${LINES[$i]}" >> $TMP_FILE || \
			{ CHANGES=$((CHANGES+1)); echo "${LINES[$i]}" | sed -E 's/^(.*)_abort (.+)$/\1_abort '$((i+1))' \2/g'; } >> "$TMP_FILE"
	done

	echo " ($CHANGES)"
	_cp "$TMP_FILE" "$1" >/dev/null
}

