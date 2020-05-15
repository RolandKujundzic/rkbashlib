#!/bin/bash

#--
# Create mysql dump. Abort if error.
#
# @param save_path
# @param options
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# shellcheck disable=SC2086
#--
function _mysql_dump {
	test -z "$MYSQL_CONN" && _abort "mysql connection string MYSQL_CONN is empty"

	echo "mysqldump ... $2 > $1"
	SECONDS=0
	nice -n 10 ionice -c2 -n 7 mysqldump --single-transaction --quick $MYSQL_CONN $2 > "$1" || _abort "mysqldump ... $2 > $1 failed"
	echo "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."

	if ! test -f "$1"; then
		_abort "no such dump [$1]"
	fi

	if test -z "$(tail -1 "$1" | grep "Dump completed")"; then
		_abort "invalid mysql dump [$1]"
	fi
}

