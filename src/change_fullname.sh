#!/bin/bash

#--
# Change old_login into new_login. If login is same or both exist do nothing.
#
# @param user
# @param fullname
#--
function _change_fullname {
	[[ -z "$1" || -z "$2" ]] && return
	
	_run_as_root
	_require_file '/etc/passwd'
	_require_program chfn
	_require_program getent
	_require_program cut

	local FULLNAME=`getent passwd "$1" | cut -d ':' -f 5 | cut -d ',' -f 1`
	test "$2" = "$FULLNAME" && return

	_msg "Change full name of $1 to $2"
	chfn -f "$2" "$1" || _abort "chfn -f '$2' '$1'"
}

