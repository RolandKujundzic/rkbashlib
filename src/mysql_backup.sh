#!/bin/bash

#------------------------------------------------------------------------------
# Backup mysql database. Run as cron job. Create daily backup.
# Run as cron job, e.g. daily every 1/2 hour
#
# 10 8,9,10,11,12,13,14,15,16,17,18,19,20  * * *  /path/to/mysql_backup.sh
#
# @param backup directory
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @require abort, cd, cp, mysql_dump
#------------------------------------------------------------------------------
function _mysql_backup {

	local DUMP="mysql_dump."`date +"%H%M"`".tgz"
	local DAILY_DUMP="mysql_dump."`date +"%Y%m%d"`".tgz"
	local FILES="'tables.txt'"

	if test -f "tables.txt"; then
		_abort "last dump failed or is still running"
	fi

	_cd $1

	echo "update $DUMP and $DAILY_DUMP" > $LOCK

	# dump structure
	echo "create_tables.sql" > tables.txt
	_mysql_dump "create_tables.sql" "-d"
	FILES="$FILES 'create_tables.sql'"

	for T in $(mysql $MYSQL_CONN -e 'show tables' -s --skip-column-names)
	do
		# dump table
		echo $T >> tables.txt
		_mysql_dump "$T"".sql" "--extended-insert=FALSE --no-create-info=TRUE"
		FILES="$FILES '$T'"
	done

	echo "archive database dump as $DUMP"
	tar -czf "$DUMP" $FILES || _abort "tar -czf '$DUMP' $FILES failed"

	_cp "$DUMP" "$DAILY_DUMP"

	# cleanup
	rm $FILES

	_cd
}
