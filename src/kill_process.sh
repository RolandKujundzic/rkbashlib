#!/bin/bash

#------------------------------------------------------------------------------
# If pid is file:path/to/process.pid try [head -3 path/to/process.pid | grep PID=] first
# otherwise assume file contains only pid. If pid is rx:REGULAR_EXPRESSION try
# [ps aux | grep -e "REGULAR_EXPRESSION"].
#
# @param pid [pid|file|rx]:...
# @param abort if process does not exist (optional)
# @require _abort
#------------------------------------------------------------------------------
function _kill_process {
	local MY_PID=

	case $1 in
		file:*)
			local PID_FILE="${1#*:}"

			if ! test -s "$PID_FILE"; then
				_abort "no such pid file $PID_FILE"
			fi

			MY_PID=`head -3 "$PID_FILE" | grep "PID=" | sed -e "s/PID=//"`
			if test -z "$MY_PID"; then
				MY_PID=`cat "$PID_FILE" | grep -E '^[1-3][0-9]{0,4}$'`
			fi
			;;
		pid:*)
			MY_PID="${1#*:}"
			;;
		rx:*)
			MY_PID=`ps aux | grep -E "${1#*:}" | awk '{print $2}'`
			;;
	esac

	if test -z "$MY_PID"; then
		_abort "no pid found ($1)"
	fi

	local FOUND_PID=`ps aux | awk '{print $2}' | grep -E '^[123][0-9]{0,4}$' | grep "$MY_PID"`
	if test -z "$FOUND_PID"; then
		if ! test -z "$2"; then
			_abort "no such pid $MY_PID"
		fi

		echo "no such pid $MY_PID"
	else
		echo "kill $MY_PID"
		kill "$MY_PID" || _abort "kill '$MY_PID'"
	fi
}

