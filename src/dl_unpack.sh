#!/bin/bash

#------------------------------------------------------------------------------
# Download and unpack archive (tar or zip).
#
# @param string directory name
# @param string download url
# @require abort mv
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
	local UNPACK_CMD=

	if test "$EXTENSION" = "zip"; then
		UNPACK_CMD="unzip"
		echo "Unpack zip: $UNPACK_CMD '$ARCHIVE'"
		unzip "$ARCHIVE"
	else
		UNPACK_CMD="tar -xf"
		echo "Unpack tar: $UNPACK_CMD '$ARCHIVE'"
		tar -xf "$ARCHIVE"
	fi

	if ! test -d "$1"; then
		local BASE="${ARCHIVE%.*}"

		if test -d $BASE; then
			_mv "$BASE" "$1"
		else
			_abort "$UNPACK_CMD $ARCHIVE failed"
		fi
  fi
}
