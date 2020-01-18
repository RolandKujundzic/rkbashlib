#!/bin/bash

#--
# Load sql dump $1 (ask). Based on rks-db_connect - implement custom _sql_load if missing.
#
# @require _require_program _require_file _confirm
#--
function _sql_load {
	_require_program "rks-db_connect"
	_require_file "$1"

	_confirm "load sql create dump '$1'?" 1
	test "$CONFIRM" = "y" && rks-db_connect load "$1" --q1=n --q2=y
}
