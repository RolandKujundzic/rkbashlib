#!/bin/bash

#------------------------------------------------------------------------------
# Abort with error message. Use NO_ABORT=1 for just warning output.
#
# @exit
# @global APP, NO_ABORT
# @param abort message
#------------------------------------------------------------------------------
function _abort {
	if test "$NO_ABORT" = 1; then
		echo "WARNING: $1"
		return
	fi

	echo -e "\nABORT: $1\n\n" 1>&2

	if ! test -z "$APP"; then
		# make shure APP dies even if _abort is called from subprocess
  	kill $(ps aux | grep "$APP" | awk '{print $2}')
	fi

	exit 1
}

