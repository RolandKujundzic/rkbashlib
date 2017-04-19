#!/bin/bash

#------------------------------------------------------------------------------
# Backup mysql database. Run as cron job. Create daily backup.
# Run as cron job, e.g. daily every 1/2 hour
#
# 10 8,9,10,11,12,13,14,15,16,17,18,19,20  * * *  /path/to/mysql_backup.sh
#
# @param backup directory
# @require abort, cd, cp, mysql_dump
#------------------------------------------------------------------------------
function _mysql_backup {

	local LOCK=mysql_backup.lock
	local MIN_SUFFIX=`date +".%H%M.sql"`
	local DAY_SUFFIX=`date +".%Y%m%d.sql"`
	local DUMP="mysql_dump$MIN_SUFFIX"".tar.gz"
	local DAILY_DUMP="mysql_dump$DAY_SUFFIX"".tar.gz"

	if test -f "$LOCK"; then
		_abort "last dump failed or is still running"
	fi

	_cd $1

	echo "update $DUMP and $DAILY_DUMP" > $LOCK
	_mysql_dump "mysql_create$MIN_SUFFIX" "-d"
	_mysql_dump "mysql_insert$MIN_SUFFIX" "--no-create-info=TRUE"

	echo "archive database dump as $DUMP"
	tar -czf "$DUMP" "mysql_create$MIN_SUFFIX" "mysql_insert$MIN_SUFFIX" || _abort "tar -czf '$DUMP' failed"

	_cp "$DUMP" "$DAILY_DUMP"

	# cleanump
	rm "mysql_create$MIN_SUFFIX" "mysql_insert$MIN_SUFFIX" "$LOCK"

	_cd
}

