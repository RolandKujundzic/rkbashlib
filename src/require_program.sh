#!/bin/bash

#--
# Abort if program (function) $1 does not exist (and $2 is not 1).
#
# @param program
# @param return_bool (default = 0)
# @require _abort
# @return bool (if $2==1)
#--
function _require_program {
	local TYPE=`type -t "$1"`
	local ERROR=0
  local CHECK=$2

	test "$TYPE" = "function" && return $ERROR

	command -v "$1" >/dev/null 2>&1 || ERROR=1

  if ((!CHECK && ERROR)); then
    echo "No such program [$1]" && exit 1
  fi

	return $ERROR
}

