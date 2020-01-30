#!/bin/bash

#--
# Drop Mysql User $1. Set MYSQL otherwise "mysql -u root" is used.
#
# @param name
# @param host (default = localhost)
# @global MYSQL (use 'mysql -u root' if empty)
# @require _abort _confirm _msg
#--
function _mysql_drop_user {
	local NAME=$1
	local HOST="${2:-localhost}"

	if test -z "$MYSQL"; then
		local MYSQL
		test "$UID" = "0" && MYSQL="mysql -u root" || MYSQL="sudo mysql -u root"
	fi

	local HAS_USER=`echo "SELECT user FROM user WHERE user='$NAME' AND host='$HOST'" | $MYSQL mysql 2>/dev/null`
	if test -z "$HAS_USER"; then
		_msg "no such user $NAME@$HOST"
		return
	else
		_confirm "Drop user $NAME@$HOST?" 1
		test "$CONFIRM" = "y" || _abort "user abort"
		{ echo "DROP USER '$NAME'@'$HOST'" | $MYSQL mysql; } || _abort "drop user '$NAME'@'$HOST' failed"
	fi
}

