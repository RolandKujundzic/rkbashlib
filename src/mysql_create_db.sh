#!/bin/bash

#--
# Create Mysql Database and user. Define MYSQL="mysql -u root" if not set 
# and user is root. If dbname and password are empty try to autodetect from 
# settings.php or index.php. DB_CHARSET=[utf8|latin1|utf8mb4=ask] or empty
# (=server default) if nothing is set.
#
# @param dbname = username
# @param password
# @global MYSQL DB_CHARSET
# @export DB_NAME DB_PASS
# @require _abort _mysql_split_dsn _mysql_conn
#--
function _mysql_create_db {
	DB_NAME=$1
	DB_PASS=$2

	_mysql_split_dsn
	_mysql_conn 1

	local HAS_DB=`echo "SHOW CREATE DATABASE $DB_NAME" | $MYSQL 2> /dev/null && echo "ok"`
	if ! test -z "$HAS_DB"; then
		echo "Keep existing database $DB_NAME"
		return
	fi

	local CHARSET=

	if test "$DB_CHARSET" = "utf8mb4"; then
		CHARSET="DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci"
	elif test "$DB_CHARSET" = "utf8"; then
		CHARSET="DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci"
	elif test "$DB_CHARSET" = "latin1"; then
		CHARSET="DEFAULT CHARACTER SET latin1 DEFAULT COLLATE latin1_german1_ci"
	else
		_confirm "Use charset utf8mb4"
		if test "$CONFIRM" = "y"; then
			CHARSET="DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci"
		fi
	fi

	echo "create mysql database $DB_NAME"
	echo "CREATE DATABASE $DB_NAME $CHARSET" | $MYSQL || _abort "create database $DB_NAME failed"
	echo "create mysql database user $DB_NAME"
	echo "GRANT ALL ON $DB_NAME.* TO '$DB_NAME'@'localhost' IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;" | $MYSQL || \
		_abort "create database user $DB_NAME failed"
}

