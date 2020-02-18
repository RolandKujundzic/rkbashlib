#!/bin/bash

#--
# Change hostname if hostname != $1.
#
# @param hostname
# @require _abort _require_program _msg _run_as_root
#--
function _change_hostname {
	local NEW_HNAME="$1"
	test -z "$NEW_HNAME" && return

	_run_as_root
	_require_program hostname
	local CURR_HNAME=`hostname`
	test "$NEW_HNAME" = "$CURR_HNAME" && return

	_require_program hostnamectl
	_msg "change hostname '$CURR_HNAME' to '$NEW_HNAME'"
	hostnamectl set-hostname "$NEW_HNAME" || _abort "hostnamectl set-hostname '$NEW_HNAME'"
}

