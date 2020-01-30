#!/bin/bash

#--
# Check if .my.cnf exists. If found export DB_PASS and DB_NAME. If $SQL_PASS 
# and $MYSQL are set save $MYSQL as $MYSQL_SQL. Otherwise set MYSQL=[mysql --defaults-file=.my.cnf].
#
# @global SQL_PASS MYSQL
# @export DB_NAME DB_PASS MYSQL(=mysql --defaults-file=.my.cnf)
# @param path to .my.cnf (default = .my.cnf)
#--
function _my_cnf {
	local MY_CNF="$1"

	if ! test -z "$SQL_PASS" && ! test -z "$MYSQL"; then
		local MYSQL_SQL="$MYSQL"
	fi

	test -z "$MY_CNF" && MY_CNF=".my.cnf"
	test -s "$MY_CNF" || return

	local MY_CNF_CONTENT=`cat ".my.cnf" 2> /dev/null`
	test -z "$MY_CNF_CONTENT" && return

	DB_PASS=`grep password "$MY_CNF" | sed -E 's/.*=\s*//g'`
	DB_NAME=`grep user "$MY_CNF" | sed -E 's/.*=\s*//g'`

	if ! test -z "$DB_PASS" && ! test -z "$DB_NAME" && test -z "$MYSQL_SQL"; then
		MYSQL="mysql --defaults-file=.my.cnf"
	fi
}

