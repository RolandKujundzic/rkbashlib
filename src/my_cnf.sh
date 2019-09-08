#!/bin/bash

#------------------------------------------------------------------------------
# Check if .my.cnf exists. 
#
# @export DB_NAME DB_PASS MYSQL(=mysql --defaults-file=.my.cnf)
# @param path to .my.cnf (default = .my.cnf)
#------------------------------------------------------------------------------
function _my_cnf {
	local MY_CNF="$1"

	if test -z "$MY_CNF"; then
		MY_CNF=".my.cnf"
	fi

	if ! test -s "$MY_CNF"; then
		return
	fi

	local MY_CNF_CONTENT=`cat ".my.cnf" 2> /dev/null`
	if test -z "$MY_CNF_CONTENT"; then
		return
	fi

	DB_PASS=`grep password "$MY_CNF" | sed -E 's/.*=\s*//g'`
	DB_NAME=`grep user "$MY_CNF" | sed -E 's/.*=\s*//g'`

	if ! test -z "$DB_PASS" && ! test -z "$DB_NAME"; then
		MYSQL="mysql --defaults-file=.my.cnf"
	fi
}

