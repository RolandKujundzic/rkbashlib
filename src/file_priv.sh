#!/bin/bash

#------------------------------------------------------------------------------
# Change file privileges in directory (ignore .dot_directories, recursive)
#
# @param directory
# @param privileges
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

	find "$1" -type f ! -name '.*' ! -name '*.sh' -exec chmod $PRIV {} \;
}

