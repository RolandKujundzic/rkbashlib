#!/bin/bash

#--
# Create .htaccess file in directory $1 if missing. 
# @param path to directory
# @param option (deny|auth:user:pass)
#--
function _htaccess {
	local htpasswd basic_auth

	if test "$2" = "deny"; then
		_append_txt "$1/.htaccess" "Require all denied"
	elif test "${2:0:5}" = "auth:"; then
		_split ":" "$2" >/dev/null
		test -z "${SPLIT[1]}" && _abort "empty username"
		test -z "${SPLIT[2]}" && _abort "empty password"

		htpasswd=$(realpath "$1")"/.htpasswd"
		basic_auth="AuthType Basic
AuthName \"Require Authentication\"
AuthUserFile \"$htpasswd\"
require valid-user"
		_append_txt "$1/.htaccess" "$basic_auth"

		_msg "add user ${SPLIT[1]} to $1/.htpasswd"
		echo "${SPLIT[2]}" | htpasswd -i "$1/.htpasswd" "${SPLIT[1]}" 2>/dev/null

		if [[ "$1" =~ data/ ]]; then
			_chown "$1/.htpasswd" rk www-data
			_chmod 660 "$1/.htpasswd"
		fi
	else
		_abort "invalid second parameter use deny|auth:user:pass"
	fi

	if [[ "$1" =~ data/ ]]; then
		_chown "$1/.htaccess" rk www-data
		_chmod 660 "$1/.htaccess"
	fi
}

