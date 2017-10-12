#!/bin/bash

#------------------------------------------------------------------------------
# Create mysql dump. Abort if error.
#
# @param save_path
# @param options
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# @require _abort
#------------------------------------------------------------------------------
function _mysql_dump {

	if test -z "$MYSQL_CONN"; then
		_abort "mysql connection string MYSQL_CONN is empty"
	fi

	echo "mysqldump ... $2 > $1"
	SECONDS=0
	nice -n 10 ionice -c2 -n 7 mysqldump --single-transaction --quick $MYSQL_CONN $2 > "$1" || _abort "mysqldump ... $2 > $1 failed"
	echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."

	if ! test -f "$1"; then
		_abort "no such dump [$1]"
	fi

	local DUMP_OK=`tail -1 "$1" | grep "Dump completed"`
	if test -z "$DUMP_OK"; then
		_abort "invalid mysql dump [$1]"
	fi
}

