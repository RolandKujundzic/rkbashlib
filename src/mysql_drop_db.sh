#!/bin/bash

#--
# Create Mysql Database and user. Define MYSQL="mysql -u root" if not set 
# and user is root. If dbname and password are empty try to autodetect from 
# settings.php or index.php. DB_CHARSET=[utf8|latin1|utf8mb4=ask] or empty
# (=server default) if nothing is set.
#
# @param dbname
# @global MYSQL (use mysql -u root if empty)
# @require _abort _confirm _msg _run_as_root
#--
function _mysql_drop_db {
	DB_NAME=$1

	if test -z "$MYSQL"; then
		_run_as_root 1
		local MYSQL="mysql -u root"
	fi

	if { echo "SHOW CREATE DATABASE $DB_NAME" | $MYSQL >/dev/null 2>/dev/null; }; then
		_confirm "Drop database $DB_NAME?" 1
		test "$CONFIRM" = "y" || _abort "user abort"
		echo "DROP DATABASE $DB_NAME" | $MYSQL || _abort "drop database $DB_NAME failed"
	else
		_msg "no such database $DB_NAME"
		return
	fi
}

