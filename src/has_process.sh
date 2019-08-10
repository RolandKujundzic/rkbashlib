#!/bin/bash

declare -A PROCESS

#------------------------------------------------------------------------------
# Export PROCESS[pid|start|time|command]. Second parameter is 2^n flag:
#
#  - 2^0 = $1 is bash script (search for /[b]in/bash.+$1.sh)
#  - 2^1 = logfile PROCESS[log] must exists
#  - 2^2 = abort if process does not exists
#  - 2^3 = abort if process exists 
#  - 2^4 = logfile has PID=PROCESS_ID in first three lines
#
# If flag containts 2^1 search for logged process id.
#
# @param command
# @param flag optional 2^n value
# @option PROCESS[log]=$1.log if empty and (flag & 2^1 = 2) or (flag & 2^4 = 16)
# @export PROCESS[pid|start|time|command] 
# @require _abort
#------------------------------------------------------------------------------
function _has_process {
	local flag=$(($2 + 0))
	local rx=" +[0-9\:]+ +[0-9\:]+ +.+[b]in.*/$1"
	local logfile_pid=
	local process=

	if test $((flag & 1)) = 1; then
		rx="/[b]in/bash.+$1.sh"
	fi

	if test -z "${PROCESS[log]}" && (test $((flag & 2)) = 2 || test $((flag & 16)) = 16); then
		PROCESS[log]="$1.log"
	fi

	if test $((flag & 2)) = 2 && ! test -f "${PROCESS[log]}"; then
		_abort "no such logfile ${PROCESS[log]}"
	fi

	if test $((flag & 16)) = 16; then
		if test -s "${PROCESS[log]}"; then
			logfile_pid=`head -3 "${PROCESS[log]}" | grep "PID=" | sed -e "s/PID=//"`

			if test -z "$logfile_pid"; then
				_abort "missing PID=PROCESS_ID in first 3 lines of $1 logfile ${PROCESS[log]}"
			fi
		else
			logfile_pid=-1
		fi
	fi
		
	if test -z "$logfile_pid"; then
		process=`ps -aux | grep -E "$rx"`
	else
		process=`ps -aux | grep -E "$rx" | grep " $logfile_pid "`		
	fi

	if test $((flag & 4)) = 4 && test -z "$process"; then
		_abort "no $1 process (rx=$rx, old_pid=$logfile_pid)"
	elif test $((flag & 8)) = 8 && ! test -z "$process"; then
		_abort "process $1 is already running (rx=$rx, old_pid=$logfile_pid)"
	fi
	
	PROCESS[pid]=`echo "$process" | awk '{print $2}'`
	PROCESS[start]=`echo "$process" | awk '{print $9}'`
	PROCESS[time]=`echo "$process" | awk '{print $10}'`
	PROCESS[command]=`echo "$process" | awk '{print $11, $12, $13, $14, $15, $16, $17, $18, $19, $20}'`

	# reset option
	PROCESS[log]=
}

