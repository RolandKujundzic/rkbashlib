#!/bin/bash

#------------------------------------------------------------------------------
# Change directory privileges. Last parameter is privileges (default = 755).
# If $1 is directory and FIND_OPT empy ignore .dot_directories and *.sh suffix.
# Use "_find ..." or "find ..." to find files.
#
# @param directory
# @param privileges
# @global FIND_OPT (_find|find options, e.g. "! -name '.*' ! -name '*.sh'")
# @require _abort
#------------------------------------------------------------------------------
function _dir_priv {
	local PRIV="${@: -1}"	# ${!#}

	if test -z "$PRIV"; then
		PRIV=755
	else
		_is_integer "$PRIV"
	fi

	local _FIND=`echo "$@" | grep -E '^_find ' | sed -E 's/^_find //g' | sed -E "s/ $PRIV\$//"`
	local FIND=`echo "$@" | grep -E '^find ' | sed -E 's/^find //g' | sed -E "s/ $PRIV\$//"`

	if ! test -z "$_FIND"; then
		_find $_FIND $FIND_OPT -type d
		_chmod $PRIV
	elif ! test -z "$FIND"; then
		echo "chmod $PRIV directories in $1/"
		find $FIND $FIND_OPT -type d -exec chmod $PRIV {} \;
	elif test -d "$1"; then
		if test -z "$FIND_OPT"; then
			echo "chmod $PRIV directories in $1/ (exclude .*)"
			find "$1" ! -name '.*' -type d -exec chmod $PRIV {} \;
		else
			echo "chmod $PRIV directories in $1/"
			find "$1" $FIND_OPT -type d -exec chmod $PRIV {} \;
		fi
	else
		_abort "invalid: _dir_priv $@"
	fi
}

