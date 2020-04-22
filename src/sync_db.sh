#!/bin/bash

#--
# Dump database on $1:$2. Require rks-db on both server.
# @param ssh e.g. user@domain.tld
# @param docroot
#--
function _sync_db {
	_msg "Create database dump in $1:$2/data/.sql with rks-db dump"
	ssh $1 "cd $2 && rks-db dump >/dev/null" || _abort "ssh $1 'cd $2 && rks-db dump failed'"

	_msg "Download and import dump"
	_rsync "$1:$2/data/.sql" "data/" >/dev/null

	local LS_LAST_DUMP="data/.sql/mysql_dump_"`date +'%Y%m%d'`
	local LAST_DUMP=`ls "$LS_LAST_DUMP"* | tail -1`

	_require_program rks-db
	rks-db load "$LAST_DUMP" >/dev/null
}
