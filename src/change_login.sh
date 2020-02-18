#!/bin/bash

#--
# Change old_login into new_login. If login is same or both exist do nothing.
# Change home directory and group (if old group name = old_login). 
#
# @param old_login
# @param new_login
# @require _abort _require_program _require_file _run_as_root _msg
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

	local OLD_GNAME=`id -g -n "$OLD"`

	killall -u username

	_require_program usermod
	_require_program groupmod

	usermod -l "$NEW" "$OLD" && _msg "changed login '$OLD' to '$NEW'" || _abort "usermod -l '$NEW' '$OLD'"

	{ test "$OLD_GNAME" = "$OLD" && groupmod --new-name "$NEW" "$OLD"; } \
		&& _msg "changed group '$OLD' to '$NEW'" || _abort "groupmod --new-name '$NEW' '$OLD'"

	{ [[ -d "/home/$OLD" && ! -d "/home/$NEW" ]] && usermod -d "/home/$NEW" -m "$NEW"; } \
		&& _msg "moved '/home/$OLD' to '/home/$NEW'" || _abort "usermod -d '/home/$NEW' -m '$NEW'"
}

