#!/bin/bash

#--
# Change file+directory privileges recursive.
#
# @param path/to/entry
# @param file privileges (default = 644)
# @param dir privileges (default = 755)
# @param main dir privileges (default = dir privleges)
# @require _abort _file_priv _dir_priv
#--
function _chmod_df {
	local CHMOD_PATH="$1"
	local FPRIV=$2
	local DPRIV=$3
	local MDPRIV=$4

	if ! test -d "$CHMOD_PATH" && ! test -f "$CHMOD_PATH"; then
		_abort "no such directory or file: [$CHMOD_PATH]"
	fi

	test -z "$FPRIV" && FPRIV=644
	test -z "$DPRIV" && DPRIV=755

	_file_priv "$CHMOD_PATH" $FPRIV
	_dir_priv "$CHMOD_PATH" $DPRIV

	if ! test -z "$MDPRIV" && test "$MDPRIV" != $"$DPRIV"; then
		echo "chmod $MDPRIV '$CHMOD_PATH'"
		chmod "$MDPRIV" "$CHMOD_PATH" || _abort "chmod $MDPRIV '$CHMOD_PATH'"
	fi
}

