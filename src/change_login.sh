#!/bin/bash

#--
# Change old_login into new_login. If login is same or both exist do nothing.
# Change home directory and group (if old group name = old_login). 
#
# @param old_login
# @param new_login
#--
function _change_login {
	local old new has_new has_old old_gname
	old="$1"
	new="$2"
	test "$old" = "$new" && return

	_run_as_root
	_require_file '/etc/passwd'

	has_new=$(grep -E "^$new:" '/etc/passwd')
	test -z "$has_new" || return

	has_old=$(grep -E "^$old:" '/etc/passwd')
	test -z "$has_old" && _abort "no such user $old"

	old_gname=$(id -g -n "$old")

	killall -u username

	_require_program usermod
	_require_program groupmod

	if usermod -l "$new" "$old"; then
		_msg "changed login '$old' to '$new'"
	else
		_abort "usermod -l '$new' '$old'"
	fi

	if test "$old_gname" = "$old" && groupmod --new-name "$new" "$old"; then
		_msg "changed group '$old' to '$new'"
	else
		_abort "groupmod --new-name '$new' '$old'"
	fi

	if [[ -d "/home/$old" && ! -d "/home/$new" ]]; then
		usermod -d "/home/$new" -m "$new" || _abort "usermod -d '/home/$new' -m '$new'"
		_msg "moved '/home/$old' to '/home/$new'"
	fi
}

