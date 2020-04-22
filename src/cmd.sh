#!/bin/bash

#--
# Execute command $1.
#
# @param command
# @param 2^n flag (2^0= no echo, 2^1= print output)
#--
function _cmd {

	# @ToDo unescape $1 to avoid eval
	local EXEC="$1"

	# change $2 into number
	local FLAG=$(($2 + 0))

	local CURR_LOG_NO_ECHO=$LOG_NO_ECHO
	test $((FLAG & 1)) = 1 && LOG_NO_ECHO=1

	_log "$EXEC" cmd
	eval "$EXEC ${LOG_CMD[cmd]}" || _abort "command failed"
	
	if test $((FLAG & 2)) = 2; then
		tail -n +5 "${LOG_FILE[cmd]}"
	else
		echo "ok"
	fi

	LOG_NO_ECHO=$CURR_LOG_NO_ECHO
}

