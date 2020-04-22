#!/bin/bash

#--
# Find document root of php project (realpath). Search for directory with 
# index.php and (settings.php file or data/ dir).
#
# @param string path e.g. $PWD (optional use $PWD as default)
# @param int don't abort if error (default = 0 = abort)
# @export DOCROOT
# @return bool (if $2=1)
#--
function _find_docroot {
	local DIR=
	local LAST_DIR=

	if ! test -z "$DOCROOT"; then
		DOCROOT=`realpath $DOCROOT`
		_msg "use existing DOCROOT=$DOCROOT"
		test -z "$DOCROOT" && { test -z "$2" && _abort "invalid DOCROOT" || return 1; }
		return 0
	fi

	if test -z "$1"; then
		DIR=$(realpath "$PWD")
	else
		DIR=$(realpath "$1")
	fi

	local BASE=`basename $DIR`
	test "$BASE" = "cms" && DOCROOT=`dirname $DIR`

	if ! test -z "$DOCROOT" && test -f "$DOCROOT/index.php" && (test -f "$DOCROOT/settings.php" || test -d "$DOCROOT/data"); then
		_msg "use DOCROOT=$DOCROOT"
		return 0
	fi

	while test -d "$DIR" && ! (test -f "$DIR/index.php" && (test -f "$DIR/settings.php" || test -d "$DIR/data")); do
		LAST_DIR="$DIR"
		DIR=$(dirname "$DIR")

		if test "$DIR" = "$LAST_DIR" || ! test -d "$DIR"; then
			test -z "$2" && _abort "failed to find DOCROOT of [$1]" || return 1
		fi
	done

	if test -f "$DIR/index.php" && (test -f "$DIR/settings.php" || test -d "$DIR/data"); then
		DOCROOT="$DIR"
	else
		test -z "$2" && _abort "failed to find DOCROOT of [$1]" || return 1
	fi

	return 0
}

