#!/bin/bash

#--
# Create directory (including parent directories) if directory does not exists.
#
# @param path
# @param flag (optional, 2^0=abort if directory already exists, 2^1=chmod 777 directory)
# @global SUDO
#--
function _mkdir {
	test -z "$1" && _abort "Empty directory path"
	local flag=$(($2 + 0))

	if ! test -d "$1"; then
		echo "mkdir -p $1"
		$SUDO mkdir -p "$1" || _abort "mkdir -p '$1'"
	else
		test $((flag & 1)) = 1 && _abort "directory $1 already exists"
		echo "directory $1 already exists"
	fi

	test $((flag & 2)) = 2 && _chmod 777 "$1"
}

