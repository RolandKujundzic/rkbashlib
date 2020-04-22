#!/bin/bash

#--
# Change password $2 of user $1 if crypted password $3 is not used.
#
# @param user
# @param password
#--
function _change_password {
	[[ -z "$1" || -z "$2" ]] && return

	_run_as_root
	_require_file '/etc/shadow'
	_require_program 'getent'

	local SALT=`getent shadow "$1" | cut -d'$' -f3`
	local EPASS=`getent shadow "$1" | cut -d':' -f2`
	MATCH=`python -c 'import crypt; print crypt.crypt("'"$2"'", "$6$'"$SALT"'")'`

	[ ${MATCH} == ${EPASS} ] && return

	_require_program 'chpasswd'
	_msg "change $1 password"
	{ echo "$1:$2" | chpasswd; } || _abort "password change failed for '$1'"
}

