#!/bin/bash

#--
# Dump database on $1:$2. Require rks-db on both server.
# @param ssh e.g. user@domain.tld
# @param docroot or docroot/dump.sql
# shellcheck disable=SC2029,SC2012
#--
function _sync_db {
	local dir base last_dump ls_last_dump
	base=$(basename "$2")
	dir=$(dirname "$2")

	_require_program rks-db

	test -s "$base.gz" && _confirm "Use existing dump $base?" 1

	if test "$CONFIRM" = "y"; then
		last_dump="$base"
	elif test "${base: -4}" = ".sql"; then
		_msg "Create database dump $1:$2"
		ssh "$1" "cd '$dir' && rks-db dump '$base' --q1=y --q2=n --q3=n >/dev/null" || _abort "ssh '$1' && cd '$dir' && rks-db dump '$base'"

		_msg 'Download dump'
		scp "$1:$2.gz" . || _abort "scp '$1:$2.gz' ."
		ssh "$1" "rm '$2.gz'" || _abort "ssh '$1' && rm '$2.gz'"
		last_dump="$base"
	else
		_msg "Create database dump in $1:$2/data/.sql"
		ssh "$1" "cd '$2' && rks-db dump --q1=y --q2=n --q3=n >/dev/null" || _abort "ssh '$1' && cd '$2' && rks-db dump"

		_msg 'Download dump'
		_rsync "$1:$2/data/.sql" "data/" >/dev/null

		ls_last_dump='data/.sql/mysql_dump_'$(date +'%Y%m%d')
		last_dump=$(ls "$ls_last_dump"* | tail -1)
	fi

	_msg "Import dump $last_dump"
	rks-db load "$last_dump" >/dev/null
}

