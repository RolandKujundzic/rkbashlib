#!/bin/bash

test -z "$RKSCRIPT_DIR" && RKSCRIPT_DIR="$HOME/.rkscript/$$"

if declare -A __hash=([key]=value) 2>/dev/null; then
	test "${__hash[key]}" = 'value' || { echo -e "\nERROR: declare -A\n"; exit 1; }
	unset __hash
else
	echo -e "\nERROR: declare -A\n"
	exit 1  
fi  

if test "${@: -1}" = 'help'; then
	for a in ps tr xargs head grep awk find sed sudo cd chown chmod mkdir rm ls; do
		command -v $a >/dev/null || { echo -e "\nERROR: missing $a\n"; exit 1; }
	done
fi

#--
# Abort with error message. Use NO_ABORT=1 for just warning output (return 1, export ABORT=1).
#
# @exit
# @global APP NO_ABORT
# @export ABORT
# @param string abort message|line number
# @param abort message (optional - use if $1 = line number)
# shellcheck disable=SC2034,SC2009
#--
function _abort {
	local msg line
	msg="$1"

	if ! test -z "$2"; then
		msg="$2"
		line="[$1]"
	fi

	if test "$NO_ABORT" = 1; then
		ABORT=1
		echo "WARNING$line: $msg"
		return 1
	fi

	local frame trace
	if type -t caller >/dev/null 2>/dev/null; then
		frame=0
		trace=$(while caller $frame; do ((frame++)); done)
		msg="$msg\n\n$trace"
	fi

	echo -e "\nABORT$line: $msg\n" 1>&2

	local other_pid=

	if ! test -z "$APP_PID"; then
		# make shure APP_PID dies
		for a in $APP_PID; do
			other_pid=$(ps aux | grep -E "^.+\\s+$a\\s+" | awk '{print $2}')
			test -z "$other_pid" || kill "$other_pid" 2>/dev/null 1>&2
		done
	fi

	if ! test -z "$APP"; then
		# make shure APP dies
		other_pid=$(ps aux | grep "$APP" | awk '{print $2}')
		test -z "$other_pid" || kill "$other_pid" 2>/dev/null 1>&2
	fi

	exit 1
}

