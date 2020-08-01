#!/bin/bash

#--
# Switch to sudo mode. Switch back after command is executed.
#
# @global LOG_CMD[sudo] 
# @param command
# @param optional flag (1=try sudo if normal command failed)
# shellcheck disable=SC2034
#--
function _sudo {
	local curr_sudo exec flag
	curr_sudo="$SUDO"

	# ToDo: unescape $1 to avoid eval. Example: use [$EXEC] instead of [eval "$EXEC"]
	# and [_sudo "cp 'a' 'b'"] will execute [cp "'a'" "'b'"].
	exec="$1"

	# change $2 into number
	flag=$(($2 + 0))

	if test "$USER" = "root"; then
		_log "$exec" sudo
		eval "$exec ${LOG_CMD[sudo]}" || _abort "$exec"
	elif test $((flag & 1)) = 1 && test -z "$curr_sudo"; then
		_log "$exec" sudo
		eval "$exec ${LOG_CMD[sudo]}" || \
			( echo "try sudo $exec"; eval "sudo $exec ${LOG_CMD[sudo]}" || _abort "sudo $exec" )
	else
		SUDO=sudo
		_log "sudo $exec" sudo
		eval "sudo $exec ${LOG_CMD[sudo]}" || _abort "sudo $exec"
		SUDO="$curr_sudo"
	fi

	LOG_LAST=
}

