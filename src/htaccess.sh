#!/bin/bash

#------------------------------------------------------------------------------
# Create .htaccess file in directory $1 if missing. Options $2:
#
# - deny
# - auth
#
# @param path to directory
# @param option (e.g. deny, auth)
# @require _mkdir _abort
#------------------------------------------------------------------------------
function _htaccess {
	if test "$2" = "deny"; then
		if ! test -f "$1/.htaccess"; then
			_mkdir "$1"
			echo "Require all denied" > "$1/.htaccess"
		else
			local has_deny=`cat "$1/.htaccess" | grep 'Require all denied'`
			if test -z "$has_deny"; then
				echo "Require all denied" > "$1/.htaccess"
			fi
		fi
	elif test "$2" = "auth"; then
		_abort "ToDo ..."
	fi
}
