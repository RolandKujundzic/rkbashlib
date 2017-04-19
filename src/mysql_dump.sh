#!/bin/bash

#------------------------------------------------------------------------------
# Create mysql dump. Abort if error.
#
# @param path
# @param options
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# @require abort
#------------------------------------------------------------------------------
function _mysql_dump {

	if test -z "$MYSQL_CONN"; then
		_abort "mysql connection string MYSQL_CONN is empty"
	fi

	echo "mysqldump $2 ... > $1"
	mysqldump $2 $MYSQL_CONN > "$1" || _abort "mysqldump $2 ... > $1 failed"

	if ! test -f "$1"; then
		_abort "no such dump [$1]"
	fi

	local DUMP_OK=`tail -1 "$1" | grep "Dump completed"`
	if test -z "$DUMP_OK"; then
		_abort "invalid mysql dump [$1]"
	fi
}

