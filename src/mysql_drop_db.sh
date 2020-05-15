#!/bin/bash

#--
# Drop Mysql Database $1. Define MYSQL or "mysql -u root" is used.
#
# @param database name
# @global MYSQL (use 'mysql -u root' if empty)
# shellcheck disable=SC2153,SC2086
#--
function _mysql_drop_db {
	local name mysql
	mysql="$MYSQL"
	name="$1"

	if test -z "$mysql"; then
		test "$UID" = "0" && mysql="mysql -u root" || mysql="sudo mysql -u root"
	fi

	if { echo "SHOW CREATE DATABASE $name" | $mysql >/dev/null 2>/dev/null; }; then
		_confirm "Drop database $name?" 1
		test "$CONFIRM" = "y" || _abort "user abort"

		{ echo "DROP DATABASE $name" | $mysql; } || _abort "drop database $name failed"

		# drop user too if DB_NAME=DB_USER and DB_HOST=localhost
		test -z "$(echo "SELECT db FROM db WHERE user='$name' AND db='$name' AND host='localhost'" | $mysql mysql 2>/dev/null)" || \
			_mysql_drop_user $name
	else
		_msg "no such database $NAME"
		return
	fi
}

