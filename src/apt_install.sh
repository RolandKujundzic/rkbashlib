#!/bin/bash

#------------------------------------------------------------------------------
# Install apt packages.
#
# @require _abort _run_as_root
#------------------------------------------------------------------------------
function _apt_install {
	local CURR_LOG_NO_ECHO=$LOG_NO_ECHO
	LOG_NO_ECHO=1

	for a in $1
	do
		if test -d "$RKSCRIPT_DIR/apt/$a"; then
			echo "already installed, skip: apt -y install $a"
		else
			apt -y install $a || _abort "apt -y install $a"
			_log "apt -y install $a" apt/$a
		fi
	done

	LOG_NO_ECHO=$CURR_LOG_NO_ECHO
}

