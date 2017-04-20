#!/bin/bash

#------------------------------------------------------------------------------
# Restore mysql database. Use mysql_dump.TS.tgz created with mysql_backup.
#
# @param dump_archive
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @require abort, extract_tgz, cd, cp, rm, mkdir, mysql_load
#------------------------------------------------------------------------------
function _mysql_restore {

	local TMP_DIR="/tmp/mysql_dump"
	local FILE=`basename $1`

	_mkdir $TMP_DIR 1
	_cp "$1" "$TMP_DIR/$FILE"

	_cd $TMP_DIR

	_extract_tgz "$FILE" "tables.txt"

	for a in `cat tables.txt`
	do
		_mysql_load $a
	done

	_cd
	_rm $TMP_DIR
}

