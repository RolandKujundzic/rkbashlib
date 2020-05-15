#!/bin/bash

#--
# Drop Mysql User $1. Set MYSQL otherwise "mysql -u root" is used.
#
# @param name
# @param host (default = localhost)
# @global MYSQL (use 'mysql -u root' if empty)
# shellcheck disable=SC2153
#--
function _mysql_drop_user {
	local name host mysql
	mysql="$MYSQL"
	name="$1"
	host="${2:-localhost}"

	if test -z "$mysql"; then
		test "$UID" = "0" && mysql="mysql -u root" || mysql="sudo mysql -u root"
	fi

	if test -z "$(echo "SELECT user FROM user WHERE user='$name' AND host='$host'" | $mysql mysql 2>/dev/null)"; then
		_msg "no such user $name@$host"
		return
	else
		_confirm "Drop user $name@$host?" 1
		test "$CONFIRM" = "y" || _abort "user abort"
		{ echo "DROP USER '$name'@'$host'" | $mysql mysql; } || _abort "drop user '$name'@'$host' failed"
	fi
}

