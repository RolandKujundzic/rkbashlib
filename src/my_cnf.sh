#!/bin/bash

#--
# Check if .my.cnf exists. If found export DB_PASS and DB_NAME. If $SQL_PASS 
# and $MYSQL are set save $MYSQL as $MYSQL_SQL. Otherwise set MYSQL=[mysql --defaults-file=.my.cnf].
#
# @global SQL_PASS MYSQL
# @export DB_NAME DB_PASS MYSQL(=mysql --defaults-file=.my.cnf)
# @param path to .my.cnf (default = .my.cnf)
# shellcheck disable=SC2120
#--
function _my_cnf {
	local my_cnf mysql_sql
	my_cnf="$1"

	[[ -z "$SQL_PASS" || -z "$MYSQL" ]] || mysql_sql="$MYSQL"

	test -z "$my_cnf" && my_cnf=".my.cnf"
	test -s "$my_cnf" || return
	test -z "$(cat ".my.cnf" 2>/dev/null)" && return

	DB_PASS=$(grep password "$my_cnf" | sed -E 's/.*=\s*//g')
	DB_NAME=$(grep user "$my_cnf" | sed -E 's/.*=\s*//g')

	if ! test -z "$DB_PASS" && ! test -z "$DB_NAME" && test -z "$mysql_sql"; then
		MYSQL="mysql --defaults-file=.my.cnf"
	fi
}

