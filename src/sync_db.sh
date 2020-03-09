#!/bin/bash

#--
# Dump database on $1:$2. Require rks-db_connect on both server.
# @param ssh e.g. user@domain.tld
# @param docroot
# @require _abort _require_program
#--
function _sync_db {
	ssh $1 "cd $2 && rks-db_connect dump" || _abort 
	_rsync "$1:$2/data/.sql" "data/"

	local LS_LAST_DUMP="data/.sql/mysql_dump_"`date +'%Y%m%d'`
	local LAST_DUMP=`ls "$LS_LAST_DUMP"* | tail -1`

	_require_program rks-db_connect
	rks-db_connect load "$LAST_DUMP"
}
