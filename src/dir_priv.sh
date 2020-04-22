#!/bin/bash

#--
# Change directory privileges (recursive).
#
# @param directory
# @param privileges (default 755)
# @param options (default "! -path '/.*/'")
#--
function _dir_priv {
	_require_program realpath

	local DIR=`realpath "$1"`
	test -d "$DIR" || _abort "no such directory [$DIR]"

	local PRIV="$2"
	if test -z "$PRIV"; then
		PRIV=755
	else
		_is_integer "$PRIV"
	fi

	local MSG="chmod $PRIV directories in $1/"

	if test -z "$3"; then
    FIND_OPT="! -path '/.*/'"
    MSG="$MSG ($FIND_OPT)"
	else
    FIND_OPT="$3"
    MSG="$MSG ($FIND_OPT)"	
  fi

	_msg "$MSG"
	find "$1" $FIND_OPT -type d -exec chmod $PRIV {} \; || _abort "find '$1' $FIND_OPT -type d -exec chmod $PRIV {} \;"
}

