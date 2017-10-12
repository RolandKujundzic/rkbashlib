#!/bin/bash

#------------------------------------------------------------------------------
# Load mysql dump. Abort if error. If restore.sh exists append load command to 
# restore.sh. 
#
# @param dump_file (if empty try data/sql/mysqlfulldump.sql, setup/mysqlfulldump.sql)
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# @require _abort _confirm _mysql_conn
#------------------------------------------------------------------------------
function _mysql_load {

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

	if ! test -z "$FIX_MYSQL_DUMP"; then
		echo "fix $DUMP"
		local TMP_DUMP=`dirname $DUMP`"/_fix.sql"
		echo -e "SET FOREIGN_KEY_CHECKS=0;\nSTART TRANSACTION;\n" > $TMP_DUMP
		sed -e "s/^\/\*\!.*//" < $DUMP | sed -e "s/^INSERT INTO/INSERT IGNORE INTO/" >> $TMP_DUMP
		echo -e "\nCOMMIT;\n" >> $TMP_DUMP
		mv "$TMP_DUMP" "$DUMP"
	fi

	if test -f "restore.sh"; then
		local LOG="$DUMP"".log"
		echo "add $DUMP to restore.sh"
		echo "_restore $DUMP &" >> restore.sh
	else
		_mysql_conn
		echo "mysql ... < $DUMP"
		SECONDS=0
		mysql $MYSQL_CONN < "$DUMP" || _abort "mysql ... < $DUMP failed"
		echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."
	fi
}

