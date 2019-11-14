#!/bin/bash

#------------------------------------------------------------------------------
# Change file privileges. Last parameter is privileges (default = 644). 
# If $1 is directory and FIND_OPT empty ignore .dot_directories and *.sh.
# Use "_find ..." or "find ..." to find files.
#
# @param directory
# @param privileges
# @global FIND_OPT (_find|find options, e.g. "! -name '.*' ! -name '*.sh'")
# @require _abort
#------------------------------------------------------------------------------
function _file_priv {
	local PRIV="${@: -1}"	# ${!#}

	if test -z "$PRIV"; then
		PRIV=644
	else
		_is_integer "$PRIV"
	fi

	local _FIND=`echo "$@" | grep -E '^_find ' | sed -E 's/^_find //g' | sed -E "s/ $PRIV\$//"`
	local FIND=`echo "$@" | grep -E '^find ' | sed -E 's/^find //g' | sed -E "s/ $PRIV\$//"`

	if ! test -z "$_FIND"; then
		_find $_FIND $FIND_OPT -type f
		_chmod $PRIV
	elif ! test -z "$FIND"; then
		find $FIND $FIND_OPT -type f -exec chmod $PRIV {} \;
	elif test -d "$1"; then
		if test -z "$FIND_OPT"; then
			find "$1" ! -name '.*' ! -name '*.sh' -type f -exec chmod $PRIV {} \;
		else
			find "$1" $FIND_OPT -type f -exec chmod $PRIV {} \;
		fi
	else
		_abort "invalid: _file_priv $@"
	fi
}

