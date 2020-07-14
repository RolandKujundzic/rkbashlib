#!/bin/bash

#--
# Execute command $1.
#
# @param command
# @param 2^n flag (2^0= no echo, 2^1= print output)
#--
function _cmd {
	# @ToDo unescape $1 to avoid eval
	local exec flag curr_log_no_echo
	exec="$1"
	flag=$(($2 + 0))
	curr_log_no_echo=$LOG_NO_ECHO

	test $((flag & 1)) = 1 && LOG_NO_ECHO=1

	_log "$exec" cmd
	eval "$exec ${LOG_CMD[cmd]}" || _abort "command failed"
	
	if test $((flag & 2)) = 2; then
		tail -n +5 "${LOG_FILE[cmd]}"
	else
		echo "ok"
	fi

	LOG_NO_ECHO=$curr_log_no_echo
}

