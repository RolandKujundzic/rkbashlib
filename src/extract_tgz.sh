#!/bin/bash

#--
# Extract tgz archive $1. If second parameter is existing file or directory, 
# remove before extraction.
#
# @param tgz_file
# @param path (optional - if set check if path was created)
# @require _abort _rm
#--
function _extract_tgz {
	test -s "$1" || _abort "_extract_tgz: Invalid archive path [$1]"
	local TARGET="$2"

	if test -z "$TARGET" && test "${1: -4}" = ".tgz"; then
		TARGET="${1:0:-4}"
	fi

	if ! test -z "$TARGET" && test -d $TARGET; then
		_rm "$TARGET"
	fi

	tar -tzf "$1" >/dev/null 2>/dev/null || _abort "_extract_tgz: invalid archive '$1'" 

  echo "extract archive $1"
  SECONDS=0
  tar -xzf $1 >/dev/null || _abort "tar -xzf $1 failed"
  echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."

	if ! test -z "$TARGET" && ! test -d "$TARGET" && ! test -f "$TARGET"; then
		_abort "$TAREGET was not created"
	fi
}

