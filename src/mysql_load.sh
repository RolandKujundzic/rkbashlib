#!/bin/bash

#------------------------------------------------------------------------------
# Load mysql dump. Abort if error. If restore.sh exists append load command to 
# restore.sh
#
# @param dump_file
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# @require abort
#------------------------------------------------------------------------------
function _mysql_load {

	if test -z "$MYSQL_CONN"; then
		_abort "mysql connection string MYSQL_CONN is empty"
	fi

	if ! test -f "$1"; then
		_abort "no such mysql dump [$1]"
	fi

	local DUMP_OK=`tail -1 "$1" | grep "Dump completed"`
	if test -z "$DUMP_OK"; then
		_abort "invalid mysql dump [$1]"
	fi

	if test -f "restore.sh"; then
		echo "add $1 to restore.sh"
		echo "mysql $MYSQL_CONN < $1 &" >> restore.sh
	else
		echo "mysql ... < $1"
		SECONDS=0
		mysql $MYSQL_CONN < "$1" || _abort "mysql ... < $1 failed"
		echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."
	fi
}

