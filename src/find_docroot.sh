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
	echo "_find_docroot: [$1]"

	if test -z "$1" || ! test -d "$1"; then
		_abort "Invalid directory [$1]"
	fi

	if test -f "$DOCROOT/index.php" && ( test -f "$DOCROOT/settingxs.php" || test -d "$DOCROOT/data" ); then
		# DOCROOT already defined
		return
	fi

	local DIR=$(realpath "$1")

	if test -f "$DIR/index.php" && ( test -f "$DIR/settingxs.php" || test -d "$DIR/data" ); then
		echo "export DOCROOT=$DIR"
		DOCROOT="$DIR"
		return
	fi

	local PARENT_DIR=$(dirname "$DIR")

	if test "$DIR" != "$PARENT_DIR" && test -d "$PARENT_DIR"; then
		_find_docroot "$PARENT_DIR"
	else
		_abort "failed to find DOCROOT"
	fi
}

