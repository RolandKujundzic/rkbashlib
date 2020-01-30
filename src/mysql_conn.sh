#!/bin/bash

#--
# Export MYSQL_CONN (and if $1=1 MYSQL).
# If MYSQL_CONN is empty and DB_NAME and DB_PASS are set assume MYSQL_CONN="-h DBHOST -u DBUSER -pDBPASS DBNAME".
# If 1=$1 set MYSQL="[sudo] mysql -u root".
#
# @global MYSQL_CONN DB_NAME DB_PASS
# @export MYSQL_CONN (and MYSQL if $1=1)
# @param require root access (default = false)
# @require _abort
#--
function _mysql_conn {

	# if $1=1 DB_NAME might not exist yet
	if test -z "$1"; then
		test -z "$DB_NAME" && _abort "$DB_NAME is not set"

		if test -z "$MYSQL_CONN"; then
			test -z "$DB_PASS" && _abort "neither MYSQL_CONN nor DB_NAME and DB_PASS are set"
			MYSQL_CONN="-h localhost -u $DB_NAME -p$DB_PASS $DB_NAME"
		fi

		TRY_MYSQL=`{ echo "USE $DB_NAME" | mysql $MYSQL_CONN 2>&1; } | grep 'ERROR 1045'`
		test -z "$TRY_MYSQL" || _abort "mysql connection for $DB_NAME string is invalid: $MYSQL_CONN"

		return
	fi

	# $1=1 - root access required
	if test -z "$MYSQL"; then
		if ! test -z "$MYSQL_CONN"; then
			MYSQL="mysql $MYSQL_CONN"
		elif test "$UID" = "0"; then
			MYSQL="mysql -u root"
		else
			MYSQL="sudo mysql -u root"
		fi
	fi

	TRY_MYSQL=`{ echo "USE mysql" | $MYSQL 2>&1; } | grep 'ERROR 1045'`
	test -z "$TRY_MYSQL" || _abort "admin access to mysql database failed: $MYSQL"
}

