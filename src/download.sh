#!/bin/bash

#--
# Download for url to local file.
#
# @param string url
# @param string file
# @param bool allow_fail
#--
function _download {
	test -z "$2" && _abort "Download target path is empty"
	test -z "$1" && _abort "Download url is empty"
	test -z "$3" && echo "Download $1 as $2"


	_mkdir "$(dirname "$2")"
	_wget "$1" "$2"
	[[ -z "$3" && ! -s "$2" ]] && _abort "Download of $2 as $1 failed"

	if test -n "$3"; then
		if test -s "$2"; then
			echo "Download $1 as $2"
		elif test -f "$2"; then
			_rm "$2"
		fi
	fi
}

