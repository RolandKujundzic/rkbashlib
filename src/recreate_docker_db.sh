#!/bin/bash

#--
# Re-create database if inside docker.
#
# @param do_not_load_dump (optional, default = empty = load_dump)
# @export DB_NAME DB_PASS MYSQL_CONN
# shellcheck disable=SC2119
#--
function _recreate_docker_db {
	if grep 172.17 /etc/hosts >/dev/null; then
		echo "not inside docker - abort database recreate"
		return
	fi

	_mysql_split_dsn
	_mysql_create_db "$DB_NAME" "$DB_PASS"

	test -z "$1" && _mysql_load
}

