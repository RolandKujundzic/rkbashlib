#!/bin/bash

#--
# Change old_login into new_login. If login is same or both exist do nothing.
#
# @param old_login
# @param new_login
# @require _abort _require_program _require_file _run_as_root
#--
function _change_login {
	local OLD="$1"
	local NEW="$2"
	test "$OLD" = "$NEW" && return

	_run_as_root
	_require_file '/etc/passwd'

	local HAS_NEW=`grep -E "^$NEW:" '/etc/passwd'`
	test -z "$HAS_NEW" || return

	local HAS_OLD=`grep -E "^$OLD:" '/etc/passwd'`
	test -z "$HAS_OLD" && _abort "no such user $OLD"

	_require_program usermod
	usermod -l "$NEW" "$OLD" || _abort "usermod -l '$NEW' '$OLD'"
}

