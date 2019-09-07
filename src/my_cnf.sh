#!/bin/bash

#------------------------------------------------------------------------------
# Check if .my.cnf exists. 
#
# @export DB_NAME DB_PASS MYSQL(=mysql --defaults-file=.my.cnf)
#------------------------------------------------------------------------------
function _my_cnf {
	if ! test -s ".my.cnf"; then
		return
	fi

	DB_PASS=`grep password .my.cnf | sed -E 's/.*=\s*//g'`
	DB_NAME=`grep user .my.cnf | sed -E 's/.*=\s*//g'`

	if ! test -z "$DB_PASS" && ! test -z "$DB_NAME"; then
		MYSQL="mysql --defaults-file=.my.cnf"
	fi
}

