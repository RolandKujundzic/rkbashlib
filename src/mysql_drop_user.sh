#!/bin/bash

#--
# Drop Mysql User $1. Set MYSQL otherwise "mysql -u root" is used.
#
# @param name
# @global MYSQL (use 'mysql -u root' if empty)
# @require _abort _confirm _msg _run_as_root
#--
function _mysql_drop_user {
	local NAME=$1

	if test -z "$MYSQL"; then
		_run_as_root 1
		local MYSQL="mysql -u root"
	fi

	local HAS_USER=`echo "SELECT user FROM user WHERE user='$NAME'" | $MYSQL mysql 2>/dev/null`
	if test -z "$HAS_USER"; then
		_msg "no such user $NAME"
		return
	else
		_confirm "Drop user $NAME?" 1
		test "$CONFIRM" = "y" || _abort "user abort"
		echo "DROP USER $NAME" | $MYSQL || _abort "drop user $NAME failed"
	fi
}

