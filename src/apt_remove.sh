#!/bin/bash

#------------------------------------------------------------------------------
# Remove (purge) apt packages.
#
# @param package list
# @require _apt_clean _abort _run_as_root _confirm _rm
#------------------------------------------------------------------------------
function _apt_remove {
	_run_as_root

	for a in $1; do
		_confirm "Run apt -y remove --purge $a" 1
		if test "$CONFIRM" = "y"; then
			apt -y remove --purge $a || _abort "apt -y remove --purge $a"
			_rm ".rkscript/apt/$a"
		fi
	done

	_apt_clean
}

