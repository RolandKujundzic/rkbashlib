#!/bin/bash

#--
# Change hostname if hostname != $1.
#
# @param hostname
#--
function _change_hostname {
	local new_hname curr_hname
	new_hname="$1"
	test -z "$new_hname" && return

	_run_as_root
	_require_program hostname
	curr_hname=$(hostname)
	test "$new_hname" = "$curr_hname" && return

	_require_program hostnamectl
	_msg "change hostname '$curr_hname' to '$new_hname'"
	hostnamectl set-hostname "$new_hname" || _abort "hostnamectl set-hostname '$new_hname'"
}

