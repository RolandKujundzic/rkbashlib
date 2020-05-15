#!/bin/bash

#--
# realpath replacement on osx
#
# @param path
#--
function _realpath_osx {
	local realpath link

	_cd "$(dirname "$1")"
	link=$(readlink "$(basename "$1")")

	while [ "$link" ]; do
		_cd "$(dirname "$link")"
		link=$(readlink "$(basename "$1")")
	done

	realpath="$PWD/$(basename "$1")"

	_cd "$CURR"
	echo "$realpath"
}

