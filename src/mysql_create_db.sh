#!/bin/bash

#------------------------------------------------------------------------------
# Create Mysql Database and user. Define MYSQL="mysql -u root" if not set 
# and user is root. If dbname and password are empty try to autodetect from 
# settings.php or index.php.
#
# @param dbname = username
# @param password
# @export DB_NAME, DB_PASS
# @require abort mysql_split_dsn
#------------------------------------------------------------------------------
function _mysql_create_db {
	DB_NAME=$1
	DB_PASS=$2

	if test -z "$MYSQL"; then
		if test "$UID" = "0"; then
			MYSQL="mysql -u root"
		else
			_abort "you must be root to run [mysql -u root]"
		fi
	fi

	if test -z "$DB_NAME" && test -z "$DB_PASS" 
	then
		if test -f 'settings.php'; then
			_mysql_split_dsn settings.php
		elif test -f 'index.php'; then
			_mysql_split_dsn index.php
		fi
	fi

	if test -z "$DB_NAME" || test -z "$DB_PASS"; then
		_abort "database name [$DB_NAME] or password [$DB_PASS] is empty"
	fi

	local HAS_DB=`echo "SHOW CREATE DATABASE $DB_NAME" | $MYSQL 2> /dev/null && echo "ok"`
	if ! test -z "$HAS_DB"; then
		_abort "Please delete existing database $DB_NAME first" 
	fi

	echo "create mysql database $DB_NAME"
	echo "CREATE DATABASE $DB_NAME" | $MYSQL || _abort "create database $DB_NAME failed"
	echo "create mysql database user $DB_NAME"
	echo "GRANT ALL ON $DB_NAME.* TO '$DB_NAME'@'localhost' IDENTIFIED BY '$DB_PASS'" | $MYSQL || \
		_abort "create database user $DB_NAME failed"
}

