#!/bin/bash

#------------------------------------------------------------------------------
# Print md5sum of file.
#
# @param program
# @param abort if not found (1=abort, empty=continue)
# @export HAS_PROGRAM (abs path to program or zero)
# @require _abort
#------------------------------------------------------------------------------
function _require_program {
	command -v "$1" > /dev/null 2>&1 || ( test -z "$2" &&  _abort "No such program [$1]" )
}

