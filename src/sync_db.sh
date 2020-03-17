#!/bin/bash

#--
# Dump database on $1:$2. Require rks-db_connect on both server.
# @param ssh e.g. user@domain.tld
# @param docroot
# @require _abort _require_program _msg
#--
function _sync_db {
	_msg "Create database dump in $1:$2/data/.sql with rks-db_connect dump"
	ssh $1 "cd $2 && rks-db_connect dump >/dev/null" || _abort 

	_msg "Download and import dump"
	_rsync "$1:$2/data/.sql" "data/" >/dev/null

	local LS_LAST_DUMP="data/.sql/mysql_dump_"`date +'%Y%m%d'`
	local LAST_DUMP=`ls "$LS_LAST_DUMP"* | tail -1`

	_require_program rks-db_connect
	rks-db_connect load "$LAST_DUMP" >/dev/null
}
