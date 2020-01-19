#!/bin/bash

#--
# Create .htaccess file in directory $1 if missing. 
# @param path to directory
# @param option (deny|auth:user:pass)
# @require _mkdir _abort _append_txt _split _msg _chown _chmod
#--
function _htaccess {
	if test "$2" = "deny"; then
		_append_txt "$1/.htaccess" "Require all denied"
	elif test "${2:0:5}" = "auth:"; then
		_split ":" "$2" >/dev/null
		test -z "${_SPLIT[1]}" && _abort "empty username"
		test -z "${_SPLIT[2]}" && _abort "empty password"

		local HTPASSWD=`realpath "$1"`"/.htpasswd"
		local BASIC_AUTH="AuthType Basic
AuthName \"Require Authentication\"
AuthUserFile \"$HTPASSWD\"
require valid-user"
		_append_txt "$1/.htaccess" "$BASIC_AUTH"

		_msg "add user ${_SPLIT[1]} to $1/.htpasswd"
		htpasswd -cb "$1/.htpasswd" "${_SPLIT[1]}" "${_SPLIT[2]}" 2>/dev/null

		_chown "$1/.htpasswd" rk www-data
		_chmod 660 "$1/.htpasswd"
	else
		_abort "invalid second parameter use deny|auth:user:pass"
	fi

	_chown "$1/.htaccess" rk www-data
	_chmod 660 "$1/.htaccess"
}
