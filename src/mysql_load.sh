#!/bin/bash

#--
# Load mysql dump. Abort if error. If restore.sh exists append load command to 
# restore.sh. 
#
# @param dump_file (if empty try data/sql/mysqlfulldump.sql, setup/mysqlfulldump.sql)
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# shellcheck disable=SC2086
#--
function _mysql_load {
	local dump tmp_dump
	dump="$1"

	if ! test -f "$dump"; then
		if test -s "data/sql/mysqlfulldump.sql"; then
			dump=data/sql/mysqlfulldump.sql
		elif test -s "setup/mysqlfulldump.sql"; then
			dump=setup/mysqlfulldump.sql
		else
			_abort "no such mysql dump [$dump]"
		fi

		_confirm "Load $dump?"
		if test "$CONFIRM" != "y"; then
			echo "Do not load $dump"
			return
		fi
	fi

	if test -z "$(tail -1 "$dump" | grep "Dump completed")"; then
		_abort "invalid mysql dump [$dump]"
	fi

	if ! test -z "$FIX_MYSQL_DUMP"; then
		echo "fix $dump"
		tmp_dump="$(dirname $dump)/_fix.sql"
		echo -e "SET FOREIGN_KEY_CHECKS=0;\nSTART TRANSACTION;\n" > "$tmp_dump"
		sed -e "s/^\/\*\!.*//" < "$dump" | sed -e "s/^INSERT INTO/INSERT IGNORE INTO/" >> "$tmp_dump"
		echo -e "\nCOMMIT;\n" >> "$tmp_dump"
		mv "$tmp_dump" "$dump"
	fi

	if test -f "restore.sh"; then
		echo "add $dump to restore.sh"
		echo "_restore $dump &" >> restore.sh
	else
		_mysql_conn
		echo "mysql ... < $dump"
		SECONDS=0
		mysql $MYSQL_CONN < "$dump" || _abort "mysql ... < $dump failed"
		echo "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."
	fi
}

