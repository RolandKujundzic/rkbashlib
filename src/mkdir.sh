#!/bin/bash

#--
# Create directory (including parent directories) if directory does not exists.
#
# @param path
# @param flag (optional, 2^0=abort if directory already exists, 2^1=chmod 777 directory, 2^2=message if directory exists)
# @global SUDO
#--
function _mkdir {
	local flag
	flag=$(($2 + 0))

	test -z "$1" && _abort "Empty directory path"

	if test -d "$1"; then
		test $((flag & 1)) = 1 && _abort "directory $1 already exists"
		test $((flag & 4)) = 4 && _msg "directory $1 already exists"
	else
		_msg "mkdir -p $1"
		$SUDO mkdir -p "$1" || _abort "mkdir -p '$1'"
	fi

	test $((flag & 2)) = 2 && _chmod 777 "$1"
}

