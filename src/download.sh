#!/bin/bash

#--
# Download for url to local file.
#
# @param string url
# @param string file
# @param bool allow_fail
#--
function _download {
	if test -z "$2"; then
		_abort "Download target path is empty"
	fi

	if test -z "$1"; then
		_abort "Download url is empty"
	fi

	local PDIR=`dirname "$2"`
	_mkdir "$PDIR"
	
	if test -z "$3"; then
		echo "Download $1 as $2"
	fi

	_wget "$1" "$2"

	if test -z "$3" && ! test -s "$2"; then
		_abort "Download of $2 as $1 failed"
	fi

	if ! test -z "$3"; then
		if test -s "$2"; then
			echo "Download $1 as $2"
		elif test -f "$2"; then
			rm "$2"
		fi
	fi
}
