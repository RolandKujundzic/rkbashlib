#!/bin/bash

#------------------------------------------------------------------------------
# Download and unpack archive (tar or zip).
#
# @param string directory name
# @param string download url
# @require abort
#------------------------------------------------------------------------------
function _dl_unpack {

	if test -d "$1"; then
		echo "Use existing unpacked directory $1"
		return
	fi

	local ARCHIVE=`basename $2`

	if ! test -f "$ARCHIVE"; then
		echo "Download $2"
		wget "$2"
	fi

	if ! test -f "$ARCHIVE"; then
		_abort "No such archive $ARCHIVE - download of $2 failed"
	fi

	local EXTENSION="${ARCHIVE##*.}"

	if test "$EXTENSION" = "zip"; then
		echo "Unpack zip $ARCHIVE"
		unzip "$ARCHIVE"
	else
		echo "Unpack tar $ARCHIVE"
		tar -xf "$ARCHIVE"
	fi

	if ! test -d "$1"; then
		_abort "tar -xf $ARCHIVE failed"
  fi
}
