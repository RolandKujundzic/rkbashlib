#!/bin/bash

#------------------------------------------------------------------------------
# Switch to sudo mode. Switch back after command is executed.
#
# @param command
# @param optional flag (1=try sudo if normal command failed)
# @require _abort
#------------------------------------------------------------------------------
function _sudo {
	local CURR_SUDO=$SUDO
	SUDO=sudo

	local FLAG=$(($2 + 0))

	if test $((FLAG & 1)) = 1 && test -z "$CURR_SUDO"; then
		$1 || sudo $1 || _abort "sudo $1"
	else
		echo -e "sudo $1\nType in sudo password if necessary"
		sudo $1 || _abort "sudo $1"
	fi

	SUDO=$CURR_SUDO
}

