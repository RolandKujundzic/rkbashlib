#!/bin/bash

#------------------------------------------------------------------------------
# Download and unpack archive.
#
# @param string directory name
# @param string download url
# @require abort
#------------------------------------------------------------------------------
function _dl_unpack {

	if test -d "$1"; then
		echo "Use existing unpacked directory $1"
	fi

	local ARCHIVE=`basename $2`

	if ! test -f "$ARCHIVE"; then
		echo "Download $2"
		wget "$2"
	fi

	if ! test -f "$ARCHIVE"; then
		_abort "No such archive $ARCHIVE - download of $2 failed"
	fi

	echo "Unpack $ARCHIVE"
	tar -xf "$ARCHIVE"

	if ! test -d "$1"; then
		_abort "tar -xf $ARCHIVE failed"
  fi
}
