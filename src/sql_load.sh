#!/bin/bash

#--
# Load sql dump $1 (ask). Based on rks-db_connect - implement custom _sql_load if missing.
# If flag=1 load dump without confirmation.
#
# @param sql dump
# @param flag
# @require _require_program _require_file _confirm
#--
function _sql_load {
	_require_program "rks-db_connect"
	_require_file "$1"

	test "$2" = "1" && AUTOCONFIRM=y
	_confirm "load sql dump '$1'?" 1
	test "$CONFIRM" = "y" && rks-db_connect load >/dev/null "$1" --q1=n --q2=y
}
