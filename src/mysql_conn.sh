#!/bin/bash

#------------------------------------------------------------------------------
# Export MYSQL_CONN connection string.
# If MYSQL_CONN is empty bu DB_NAME and DB_PASS exist use these.
#
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# @require abort
#------------------------------------------------------------------------------
function _mysql_conn {

	if test -z "$MYSQL_CONN"; then
		if ! test -z "$DB_NAME" && ! test -z "$DB_PASS"; then
			MYSQL_CONN="-h localhost -u $DB_NAME -p$DB_PASS $DB_NAME"
		else
			_abort "mysql connection string MYSQL_CONN is empty"
		fi
	fi
}

