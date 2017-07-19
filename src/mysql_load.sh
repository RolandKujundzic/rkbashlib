#!/bin/bash

#------------------------------------------------------------------------------
# Load mysql dump. Abort if error. If restore.sh exists append load command to 
# restore.sh. If MYSQL_CONN is empty but DB_NAME and DB_PASS exist use these.
#
# @param dump_file (if empty try data/sql/mysqlfulldump.sql, setup/mysqlfulldump.sql)
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# @require abort confirm
#------------------------------------------------------------------------------
function _mysql_load {

	if test -z "$MYSQL_CONN"; then
		if ! test -z "$DB_NAME" && ! test -z "$DB_PASS"; then
			MYSQL_CONN="-h localhost -u $DB_NAME -p$DB_PASS $DB_NAME"
		else
			_abort "mysql connection string MYSQL_CONN is empty"
		fi
	fi

	local DUMP=$1

	if ! test -f "$DUMP"; then
		if test -s "data/sql/mysqlfulldump.sql"; then
			DUMP=data/sql/mysqlfulldump.sql
		elif test -s "setup/mysqlfulldump.sql"; then
			DUMP=setup/mysqlfulldump.sql
		else
			_abort "no such mysql dump [$DUMP]"
		fi

		_confirm "Load $DUMP?"
		if test "$CONFIRM" != "y"; then
			echo "Do not load $DUMP"
			return
		fi
	fi

	local DUMP_OK=`tail -1 "$DUMP" | grep "Dump completed"`
	if test -z "$DUMP_OK"; then
		_abort "invalid mysql dump [$DUMP]"
	fi

	if test -f "restore.sh"; then
		local LOG="$DUMP"".log"
		echo "add $DUMP to restore.sh"
		echo "mysql $MYSQL_CONN < $DUMP &> $LOG && rm $DUMP &" >> restore.sh
	else
		echo "mysql ... < $DUMP"
		SECONDS=0
		mysql $MYSQL_CONN < "$DUMP" || _abort "mysql ... < $DUMP failed"
		echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."
	fi
}

