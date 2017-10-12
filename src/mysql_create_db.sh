#!/bin/bash

#------------------------------------------------------------------------------
# Create Mysql Database and user. Define MYSQL="mysql -u root" if not set 
# and user is root. If dbname and password are empty try to autodetect from 
# settings.php or index.php.
#
# @param dbname = username
# @param password
# @export DB_NAME, DB_PASS
# @require _abort _mysql_split_dsn
#------------------------------------------------------------------------------
function _mysql_create_db {
	DB_NAME=$1
	DB_PASS=$2

	_mysql_split_dsn

	if test -z "$MYSQL"; then
		if test "$UID" = "0"; then
			MYSQL="mysql -u root"
		else
			_abort "you must be root to run [mysql -u root]"
		fi
	fi

	local HAS_DB=`echo "SHOW CREATE DATABASE $DB_NAME" | $MYSQL 2> /dev/null && echo "ok"`
	if ! test -z "$HAS_DB"; then
		echo "Keep existing database $DB_NAME"
		return
	fi

	echo "create mysql database $DB_NAME"
	echo "CREATE DATABASE $DB_NAME" | $MYSQL || _abort "create database $DB_NAME failed"
	echo "create mysql database user $DB_NAME"
	echo "GRANT ALL ON $DB_NAME.* TO '$DB_NAME'@'localhost' IDENTIFIED BY '$DB_PASS'" | $MYSQL || \
		_abort "create database user $DB_NAME failed"
}

