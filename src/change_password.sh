#!/bin/bash

#--
# Change password $2 of user $1 if crypted password $3 is not used.
#
# @param user
# @param password
# @param crypted password
# @require _abort _msg _require_progam _require_file
#--
function _change_password {
	if test -z "$1" || test -z "$2" || test -z "$3"; then
		return
	fi

	_require_file '/etc/shadow'
	local HAS_PASS=`grep -E "^$1:$2" '/etc/shadow'`
	test -z "$HAS_PASS" || return
	_require_program 'passwd'
	_msg "change $1 password"
	{ echo "$2" | passwd -q $1; } || _abort "password change failed for '$1'"
}
