#!/bin/bash

#--
# Create .htaccess file in directory $1 if missing. 
# @param path to directory
# @param option (deny|auth:user:pass)
# @require _mkdir _abort _append_txt _split _msg
#--
function _htaccess {
	if test "$2" = "deny"; then
		_append_txt "$1/.htaccess" "Require all denied"
	elif test "${2:0:5}" = "auth:"; then
		_split ":" "$2" >/dev/null
		local BASIC_AUTH="AuthType Basic
AuthName \"Require Authentication\"
AuthUserFile $1/.htpasswd
require valid-user"
		_append_txt "$1/.htaccess" "$BASIC_AUTH"
		_msg "add user ${_SPLIT[1]} to $1/.htpasswd"
		htpasswd -cb "$1/.htpasswd" "${_SPLIT[1]}" "${_SPLIT[2]}" 2>/dev/null
	else
		_abort "invalid second parameter use deny|auth:user:pass"
	fi
}
