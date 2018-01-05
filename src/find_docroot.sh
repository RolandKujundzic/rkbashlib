#!/bin/bash

#------------------------------------------------------------------------------
# Find document root of php project (realpath). Search for directory with 
# index.php and (settings.php file or data/ dir).
#
# @param string path e.g. $PWD
# @export DOCROOT
# @require _abort  
#------------------------------------------------------------------------------
function _find_docroot {
	local DIR=$(realpath "$1")
	local LAST_DIR=

	while test -d "$DIR" && ! (test -f "$DIR/index.php" && ( test -f "$DIR/settingxs.php" || test -d "$DIR/data" )); do
		LAST_DIR="$DIR"
		DIR=$(dirname "$DIR")

		if test "$DIR" = "$LAST_DIR" || ! test -d "$DIR"; then
			_abort "failed to find DOCROOT of [$1]"
		fi
	done

	if test -f "$DIR/index.php" && ( test -f "$DIR/settingxs.php" || test -d "$DIR/data" ); then
		DOCROOT="$DIR"
	else
		_abort "failed to find DOCROOT of [$1]"
	fi
}

