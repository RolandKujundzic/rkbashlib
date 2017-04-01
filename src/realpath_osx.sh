#!/bin/bash

#------------------------------------------------------------------------------
# realpath replacement on osx
#
# @param path
#------------------------------------------------------------------------------
function _realpath_osx {
	local REALPATH=
	local LINK=
	local CURR=$PWD

	cd "$(dirname "$1")"
	LINK=$(readlink "$(basename "$1")")

	while [ "$LINK" ]; do
		cd "$(dirname "$LINK")"
		LINK=$(readlink "$(basename "$1")")
	done

	REALPATH="$PWD/$(basename "$1")"

	cd "$CURR"
	echo "$REALPATH"
}

