#!/bin/bash

#--
# Create mysql dump. Abort if error.
#
# @param save_path
# @param options (or MYSQL_OPT)
# @global MYSQL_CONN or DB_(USER|HOST|NAME|PASS) MYSQL_OPT
# shellcheck disable=SC2086
#--
function _mysql_dump {
	local user host mycon myopt
	mycon="$MYSQL_CONN"
	myopt="${2:-$MYSQL_OPT}"

	if test -z "$mycon"; then
		if [[ -z "$DB_NAME" || -z "$DB_PASS" ]]; then
			_abort "mysql connection string MYSQL_CONN is empty"
		else
			user="${DB_USER:-$DB_NAME}"
			host="${DB_HOST:-localhost}"
			mycon="-h $host -u $user -p$DB_PASS $DB_NAME"
		fi
	fi

	echo "mysqldump ... $2 > $1"
	SECONDS=0
	{ nice -n 10 ionice -c2 -n 7 \
		mysqldump --single-transaction --quick $mycon $myopt | grep -v -E -e '^/\*\!50013 DEFINER=' > "$1"; } || \
			_abort "mysqldump ... $myopt > $1 failed"
	echo "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."

	test -f "$1" || _abort "no such dump [$1]"
	test -z "$(tail -1 "$1" | grep "Dump completed")" && _abort "invalid mysql dump [$1]"
}

