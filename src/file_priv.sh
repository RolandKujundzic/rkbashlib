#!/bin/bash

#------------------------------------------------------------------------------
# Change file privileges for directory (recursiv). 
#
# @param directory
# @param privileges (default 644)
# @param options (default "! -path '.*/' ! -path 'bin/*' ! -name '.*' ! -name '*.sh'")
# @require _abort _require_program
#------------------------------------------------------------------------------
function _file_priv {
	_require_program "realpath find chmod"

	local DIR=`realpath "$1"`
	test -d "$DIR" || _abort "no such directory [$DIR]"

	local PRIV="$2"
	if test -z "$PRIV"; then
		PRIV=644
	else
		_is_integer "$PRIV"
	fi

	local MSG="chmod $PRIV files in $1/"

	if test -z "$3"; then
		FIND_OPT="! -path '/.*/' ! -path '/bin/*' ! -name '.*' ! -name '*.sh'"
		MSG="$MSG ($FIND_OPT)"
	else
		FIND_OPT="$3"
		MSG="$MSG ($FIND_OPT)"
	fi

	echo "$MSG"
	find "$1" $FIND_OPT -type f -exec chmod $PRIV {} \; || _abort "find '$1' $FIND_OPT -type f -exec chmod $PRIV {} \;"
}

