#!/bin/bash

#------------------------------------------------------------------------------
# Re-create database if inside docker.
#
# @param do_not_load_dump (optional, default = empty = load_dump)
# @require _mysql_split_dsn _mysql_create_db _mysql_load
# @export DB_NAME DB_PASS MYSQL_CONN
#------------------------------------------------------------------------------
function _recreate_docker_db {
	local INSIDE_DOCKER=`cat /etc/hosts | grep 172.17`

	if test -z "$INSIDE_DOCKER"; then
		echo "not inside docker - abort database recreate"
		return
	fi

	_mysql_split_dsn
	_mysql_create_db $DB_NAME $DB_PASS

	if test -z "$1"; then
		_mysql_load
	fi
}

