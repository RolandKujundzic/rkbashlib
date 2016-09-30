#!/bin/bash

#------------------------------------------------------------------------------
# Create directory (including parent directories) if directory does not exists.
#
# @param path
# @require abort
#------------------------------------------------------------------------------
function _mkdir {

	if test -z "$1"; then	
		_abort "Empty directory path"
	fi

	if ! test -d "$1"; then
		echo "mkdir -p $1"
		mkdir -p $1 || _abort "mkdir -p '$1'"
	else
		echo "directory $1 already exists"
	fi
}

