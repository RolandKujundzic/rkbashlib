#!/bin/bash

#--
# Backup mysql database. Run as cron job. Create daily backup.
# Run as cron job, e.g. daily every 1/2 hour
#
# 10 8,9,10,11,12,13,14,15,16,17,18,19,20  * * *  /path/to/mysql_backup.sh
#
# @param backup directory
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# shellcheck disable=SC2086
#--
function _mysql_backup {
	local a dump daily_dump files
	dump="mysql_dump.$(date +"%H%M").tgz"
	daily_dump="mysql_dump.$(date +"%Y%m%d").tgz"
	files="tables.txt"

	test -f "tables.txt" && _abort "last dump failed or is still running"

	_cd "$1"

	echo "update $dump and $daily_dump"

	# dump structure
	echo "create_tables" > tables.txt
	_mysql_dump "create_tables.sql" "-d"
	files="$files create_tables.sql"

	for a in $(mysql $MYSQL_CONN -e 'show tables' -s --skip-column-names); do
		# dump table
		echo "$a" >> tables.txt
		_mysql_dump "$a.sql" "--extended-insert=FALSE --no-create-info=TRUE $a"
		files="$files $a.sql"
	done

	_create_tgz "$dump" "$files"
	_cp "$dump" "$daily_dump"
	_rm "$files"

	_cd
}

