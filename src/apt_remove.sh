#!/bin/bash

#--
# Remove (purge) apt packages.
#
# @param package list
#--
function _apt_remove {
	_run_as_root

	for a in $1; do
		_confirm "Run apt -y remove --purge $a" 1
		if test "$CONFIRM" = "y"; then
			apt -y remove --purge $a || _abort "apt -y remove --purge $a"
			_rm "$RKSCRIPT_DIR/apt/$a"
		fi
	done

	_apt_clean
}

