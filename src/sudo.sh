#!/bin/bash

#------------------------------------------------------------------------------
# Switch to sudo mode. Switch back after command is executed.
#
# @param command
# @require abort
#------------------------------------------------------------------------------
function _sudo {
	local CURR_SUDO=$SUDO
	SUDO=sudo

	echo -e "sudo $1\nType in sudo password if necessary"
	$1 || _abort "sudo command failed"

	SUDO=$CURR_SUDO
}

