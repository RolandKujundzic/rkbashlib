#!/bin/bash

#--
# Drop Mysql Database $1. Define MYSQL or "mysql -u root" is used.
#
# @param database name
# @global MYSQL (use 'mysql -u root' if empty)
#--
function _mysql_drop_db {
	local NAME=$1

	if test -z "$MYSQL"; then
		local MYSQL
		test "$UID" = "0" && MYSQL="mysql -u root" || MYSQL="sudo mysql -u root"
	fi

	if { echo "SHOW CREATE DATABASE $NAME" | $MYSQL >/dev/null 2>/dev/null; }; then
		_confirm "Drop database $NAME?" 1
		test "$CONFIRM" = "y" || _abort "user abort"

		# drop user too if DB_NAME=DB_USER and DB_HOST=localhost
		local DROP_USER=`echo "SELECT db FROM db WHERE user='$NAME' AND db='$NAME' AND host='localhost'" | $MYSQL mysql 2>/dev/null`

		{ echo "DROP DATABASE $NAME" | $MYSQL; } || _abort "drop database $NAME failed"

		test -z "$DROP_USER" || _mysql_drop_user $NAME
	else
		_msg "no such database $NAME"
		return
	fi
}

