#!/bin/bash

test -z "$RKSCRIPT_DIR" && RKSCRIPT_DIR="$HOME/.rkscript/$$"

for a in ps head grep awk find sed sudo cd chown chmod mkdir rm ls; do
  command -v $a >/dev/null || { echo "ERROR: missing $a"; exit 1; }
done

#--
# Abort with error message. Use NO_ABORT=1 for just warning output.
#
# @exit
# @global APP, NO_ABORT
# @param abort message
#--
function _abort {
	if test "$NO_ABORT" = 1; then
		echo "WARNING: $1"
		return
	fi

	echo -e "\nABORT: $1\n\n" 1>&2

	local other_pid=

	if ! test -z "$APP_PID"; then
		# make shure APP_PID dies
		for a in $APP_PID; do
			other_pid=`ps aux | grep -E "^.+\\s+$a\\s+" | awk '{print $2}'`
			test -z "$other_pid" || kill $other_pid 2> /dev/null 1>&2
		done
	fi

	if ! test -z "$APP"; then
		# make shure APP dies
		other_pid=`ps aux | grep "$APP" | awk '{print $2}'`
		test -z "$other_pid" || kill $other_pid 2> /dev/null 1>&2
	fi

	exit 1
}

