#!/bin/bash

#------------------------------------------------------------------------------
# Change file+directory privileges recursive.
#
# @param path/to/entry
# @param file privileges (default = 644)
# @param dir privileges (default = 755)
# @param main dir privileges (default = dir privleges)
# @require _abort _confirm
#------------------------------------------------------------------------------
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
	test -z "$MDPRIV" && MDPRIV=$DPRIV

	echo "Fix privleges: $CHMOD_PATH=$MDPRIV subdirectories=$DPRIV files=$FPRIV"
	chmod $MDPRIV "$CHMOD_PATH"
	find "$CHMOD_PATH" -type d -exec chmod $DPRIV {} \;
	find "$CHMOD_PATH" -type f -exec chmod $FPRIV {} \;
}

