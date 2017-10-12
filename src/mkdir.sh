#!/bin/bash

#------------------------------------------------------------------------------
# Create directory (including parent directories) if directory does not exists.
#
# @param path
# @global SUDO
# @param abort_if_exists (optional - if set abort if directory already exists)
# @require _abort
#------------------------------------------------------------------------------
function _mkdir {

	if test -z "$1"; then	
		_abort "Empty directory path"
	fi

	if ! test -d "$1"; then
		echo "mkdir -p $1"
		$SUDO mkdir -p $1 || _abort "mkdir -p '$1'"
	else
		if test -z "$2"
		then
			echo "_mkdir: ignore existing directory $1"
		else
			_abort "directory $1 already exists"
		fi
	fi
}

