#!/bin/bash

#------------------------------------------------------------------------------
# Create directory (including parent directories) if directory does not exists.
#
# @param path
# @param flag (optional, 2^0=abort if directory already exists, 2^1=chmod 777 directory)
# @global SUDO
# @require _abort
#------------------------------------------------------------------------------
function _mkdir {

	if test -z "$1"; then	
		_abort "Empty directory path"
	fi

	local FLAG=$(($2 + 0))

	if ! test -d "$1"; then
		echo "mkdir -p $1"
		$SUDO mkdir -p $1 || _abort "mkdir -p '$1'"
		test $((FLAG & 2)) = 2 && _chmod 777 "$1"
	elif test $((FLAG & 1)) = 1; then
		_abort "directory $1 already exists"
	fi
}

