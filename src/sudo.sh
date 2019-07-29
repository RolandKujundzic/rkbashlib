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

	# ToDo: unescape $1 to avoid eval. Example: use [$EXEC] instead of [eval "$EXEC"]
	# and [_sudo "cp 'a' 'b'"] will execute [cp "'a'" "'b'"].
	local EXEC="$1"

	# change $2 into number
	local FLAG=$(($2 + 0))

	if test $((FLAG & 1)) = 1 && test -z "$CURR_SUDO"; then
		eval "$EXEC" || eval "sudo $EXEC" || _abort "sudo $EXEC"
	else
		echo -e "sudo $EXEC\nType in sudo password if necessary"
		eval "sudo $EXEC" || _abort "sudo $EXEC"
	fi

	SUDO=$CURR_SUDO
}

