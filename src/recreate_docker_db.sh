#!/bin/bash

#------------------------------------------------------------------------------
# Re-create database if inside docker.
#
# @param string website directory
# @require abort confirm mysql_split_dsn mysql_create_db mysql_load
# @export DB_NAME DB_PASS MYSQL_CONN
#------------------------------------------------------------------------------
function _recreate_docker_db {
  local INSIDE_DOCKER=`cat /etc/hosts | grep 172.17`

	if ! test -z "$INSIDE_DOCKER"; then
		echo "no inside docker - abort database recreate"
		return
  fi

	_mysql_split_dsn
	_mysql_create_db $DB_NAME $DB_PASS
	_mysql_load
}

