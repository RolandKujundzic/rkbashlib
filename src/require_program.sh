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

	HAS_PROGRAM=`which "$1"`

	if test -z "$HAS_PROGRAM" && ! test -z "$2"
	then
		_abort "No such program [$1]"
	fi
}

