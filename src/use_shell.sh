#!/bin/bash

#--
# Link /bin/sh to /bin/shell.
#
# @abort
# @param abort message
#--
function _use_shell {
	test -L "/bin/sh" || _abort "no /bin/sh link"
	test -f "/bin/$1" || _abort "no such shell /bin/$1"

	if test -n "$(diff -u /bin/sh "/bin/$1")"; then
		_rm /bin/sh
		_cd /bin
		_ln "$1" sh
		_cd "$CURR" 
	fi
}

