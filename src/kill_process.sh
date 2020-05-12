#!/bin/bash

#--
# If pid is file:path/to/process.pid try [head -3 path/to/process.pid | grep PID=] first
# otherwise assume file contains only pid. If pid is rx:REGULAR_EXPRESSION try
# [ps aux | grep -e "REGULAR_EXPRESSION"].
#
# @param pid [pid|file|rx]:...
# @param abort if process does not exist (optional)
# shellcheck disable=SC2009
#--
function _kill_process {
	local msg my_pid pid_file

	case $1 in
		file:*)
			pid_file="${1#*:}"

			if ! test -s "$pid_file"; then
				_abort "no such pid file $pid_file"
			fi

			my_pid=$(head -3 "$pid_file" | grep "PID=" | sed -e "s/PID=//")
			if test -z "$my_pid"; then
				my_pid=$(grep -E '^[1-9][0-9]{0,4}$' "$pid_file")
			fi
			;;
		pid:*)
			my_pid="${1#*:}";;
		rx:*)
			my_pid=$(ps aux | grep -E "${1#*:}" | awk '{print $2}');;
	esac

	if test -z "$my_pid"; then
		_abort "no pid found ($1)"
	fi

	if test -z "$(ps aux | awk '{print $2}' | grep -E '^[1-9][0-9]{0,4}$' | grep "$my_pid")"; then
		msg="no such pid $my_pid"

		test "${1:0:5}" = "file:" && msg="$msg - update ${1:5}" 
		test -z "$2" || _abort "$msg"
		echo "$msg"
	else
		echo "kill $my_pid"
		kill "$my_pid" || _abort "kill '$my_pid'"
	fi
}

