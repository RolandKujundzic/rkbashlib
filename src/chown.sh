#!/bin/bash

#------------------------------------------------------------------------------
# Change owner and group of path
#
# @param path 
# @param owner
# @param group 
# @sudo
# @require _abort
#------------------------------------------------------------------------------
function _chown {

	if ! test -d "$1" && ! test -f "$1"
	then
		_abort "no such file or directory [$1]"
	fi

	if test -z "$2" || test -z "$3"
	then
		_abort "owner [$2] or group [$3] is empty"
	fi

	local CURR_OWNER=$(stat -c '%U' "$2")
	local CURR_GROUP=$(stat -c '%G' "$3")

	if test -z "$CURR_OWNER" || test -z "$CURR_GROUP"
	then
		_abort "stat owner [$CURR_OWNER] or group [$CURR_GROUP] of [$1] failed"
	fi

	if test "$CURR_OWNER" != "$2" || test "$CURR_GROUP" != 3
	then
		echo "sudo chown -R '$2.$3' '$1'"
		echo "sudo might ask for root password"
		_sudo "chown -R '$2.$3' '$1'"
	else
		echo "keep owner '$2.$3' of '$1'"
	fi
}

