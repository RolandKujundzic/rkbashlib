#!/bin/bash

#------------------------------------------------------------------------------
# Find document root of php project (realpath). Search for directory with 
# index.php and (settings.php file or data/ dir).
#
# @param string path e.g. $PWD (optional use $PWD as default)
# @export DOCROOT
# @require _abort  
#------------------------------------------------------------------------------
function _find_docroot {
	local DIR=
	local LAST_DIR=

	if ! test -z "$DOCROOT"; then
		DOCROOT=`realpath $DOCROOT`
		echo "use existing DOCROOT=$DOCROOT"
		return
	fi

	if test -z "$1"; then
		DIR=$(realpath "$PWD")
	else
		DIR=$(realpath "$1")
	fi

	local BASE=`basename $DIR`
	if test "$BASE"="cms"; then
		DOCROOT=`dirname $DIR`
	fi

	if ! test -z "$DOCROOT" && (test -f "$DOCROOT/index.php" && ( test -f "$DOCROOT/settings.php" || test -d "$DOCROOT/data" )); then
		echo "use DOCROOT=$DOCROOT"
		return
	fi

	while test -d "$DIR" && ! (test -f "$DIR/index.php" && ( test -f "$DIR/settings.php" || test -d "$DIR/data" )); do
		LAST_DIR="$DIR"
		DIR=$(dirname "$DIR")

		if test "$DIR" = "$LAST_DIR" || ! test -d "$DIR"; then
			_abort "failed to find DOCROOT of [$1]"
		fi
	done

	if test -f "$DIR/index.php" && ( test -f "$DIR/settings.php" || test -d "$DIR/data" ); then
		DOCROOT="$DIR"
	else
		_abort "failed to find DOCROOT of [$1]"
	fi
}

