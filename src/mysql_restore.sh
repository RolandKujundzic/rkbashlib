#!/bin/bash

#------------------------------------------------------------------------------
# Restore mysql database. Use mysql_dump.TS.tgz created with mysql_backup.
#
# @param dump_archive
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @require abort, extract_tgz, cd, cp, rm, mv, mkdir, mysql_load
#------------------------------------------------------------------------------
function _mysql_restore {

	local TMP_DIR="/tmp/mysql_dump"
	local FILE=`basename $1`

	_mkdir $TMP_DIR 1
	_cp "$1" "$TMP_DIR/$FILE"

	_cd $TMP_DIR

	_extract_tgz "$FILE" "tables.txt"

	cat create_tables.sql | sed -e 's/ datetime .*DEFAULT CURRENT_TIMESTAMP,/ timestamp,/g' > create_tables.fix.sql
	local IS_DIFFERENT=`cmp -b create_tables.sql create_tables.fix.sql`

	if ! test -z "$IS_DIFFERENT"; then
		_mv create_tables.fix.sql create_tables.sql
	fi

	for a in `cat tables.txt`
	do
		_mysql_load $a
	done

	_cd
	_rm $TMP_DIR
}

