#!/bin/bash

#------------------------------------------------------------------------------
# Create directory (including parent directories) if directory does not exists.
# @abort
#------------------------------------------------------------------------------
function _mkdir {
	if ! test -d "$1"; then
		echo "mkdir -p $1"
		mkdir -p $1 || _abort "mkdir -p $1"
	fi
}

