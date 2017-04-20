#!/bin/bash

#------------------------------------------------------------------------------
# Extract tgz archive $1. If second parameter is existing directory, remove
# before extraction.
#
# @param tgz_file
# @param path (optional - if set check if path was created)
# @require abort, rm
#------------------------------------------------------------------------------
function _extract_tgz {

	if ! test -f "$1"; then
		_abort "Invalid archive path [$1]"
	fi

	if [ ! -z "$2" && -d $2 ]; then
		_rm "$2"
	fi

  echo "extract archive $1"
  SECONDS=0
  tar -xzf $1 || _abort "tar -xzf $1 failed"
  echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."

	tar -tzf $1 > /dev/null || _abort "invalid archive $1" 

	if [ ! -z "$2" && [ ! -d "$2" || ! -f "$2"]]; then
		_abort "Path $2 was not created"
	fi
}

