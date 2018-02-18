#!/bin/bash

#------------------------------------------------------------------------------
# Download source url to target path.
#
# @param string source url
# @param string target path
# @require _abort _mkdir _download
#------------------------------------------------------------------------------
function _cdn_dl {
	local SUFFIX=`echo "$2" | awk -F . '{print $NF}'`

	_download "$1" "$2"
	_download "$1.map" "$2.map" 1

	echo -e "\nAdd to <head>"

	if test "$SUFFIX" = "css" && test -f "$2"; then
		echo "<link rel=\"stylesheet\" href=\"$2\" />"
	elif test "$SUFFIX" = "js" && test -f "$2"; then
		echo "<script src=\"$2\"></script>"
	fi

	echo 
}

