#!/bin/bash

#------------------------------------------------------------------------------
# Change directory privileges in directory to 755 (ignore .dot_dir, recursive)
#
# @param directory
# @param privileges 755
# @require _abort _is_integer
#------------------------------------------------------------------------------
function _dir_priv {

	if ! test -d "$1"; then
		_abort "no such directory [$1]"
	fi

	local PRIV="$2"

	if test -z "$PRIV"; then
		PRIV=755
	else
		_is_integer "$PRIV"
	fi

	find "$1" -type d ! -name '.*' -exec chmod $PRIV {} \;
}

