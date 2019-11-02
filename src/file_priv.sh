#!/bin/bash

#------------------------------------------------------------------------------
# Change file privileges in directory (ignore .dot_directories, recursive)
#
# @param directory
# @param privileges
# @global FILE_PRIV_EXCLUDE (if empty use ! -name '.*' ! -name '*.sh')
# @require _abort
#------------------------------------------------------------------------------
function _file_priv {
	if ! test -d "$1"; then
		_abort "no such directory [$1]"
	fi

	local PRIV="$2"

	if test -z "$PRIV"; then
		PRIV=644
	else
		_is_integer "$PRIV"
	fi

	test -z "$FILE_PRIV_EXCLUDE" && FILE_PRIV_EXCLUDE="! -name '.*' ! -name '*.sh'"

	local i=; local a=; local LIST=()
	while read a; do
		LIST+=("$a")
	done <<< `find "$1" -type f $FILE_PRIV_EXCLUDE 2>/dev/null`

	for ((i = 0; i < ${#LIST[@]}; i++)); do
		_chmod $PRIV "${LIST[$i]}"
	done
}

