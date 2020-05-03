#!/bin/bash

#--
# Change password $2 of user $1 if crypted password $3 is not used.
#
# @param user
# @param password
# shellcheck disable=SC2016
#--
function _change_password {
	[[ -z "$1" || -z "$2" ]] && return

	_run_as_root
	_require_file '/etc/shadow'
	_require_program 'getent'

	local salt epass match
	salt=$(getent shadow "$1" | cut -d'$' -f3)
	epass=$(getent shadow "$1" | cut -d':' -f2)
	match=$(python -c 'import crypt; print crypt.crypt("'"$2"'", "$6$'"$salt"'")')

	test "${match}" = "${epass}" && return

	_require_program 'chpasswd'
	_msg "change $1 password"
	{ echo "$1:$2" | chpasswd; } || _abort "password change failed for '$1'"
}

