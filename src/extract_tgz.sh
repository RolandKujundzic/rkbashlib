#!/bin/bash

#--
# Extract tgz archive $1. If second parameter is existing file or directory, 
# remove before extraction.
#
# @param tgz_file
# @param path (optional - if set check if path was created)
# global SECONDS
#--
function _extract_tgz {
	test -s "$1" || _abort "_extract_tgz: Invalid archive path [$1]"
	local target 
	target="$2"

	if test -z "$target" && test "${1: -4}" = ".tgz"; then
		target="${1:0:-4}"
	fi

	if ! test -z "$target" && test -d "$target"; then
		_rm "$target"
	fi

	tar -tzf "$1" >/dev/null 2>/dev/null || _abort "_extract_tgz: invalid archive '$1'"

  echo "extract archive $1"
  SECONDS=0
  tar -xzf "$1" >/dev/null || _abort "tar -xzf $1 failed"
  echo "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."

	if ! test -z "$target" && ! test -d "$target" && ! test -f "$target"; then
		_abort "$target was not created"
	fi
}

