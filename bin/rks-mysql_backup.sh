#!/bin/bash
MERGE2RUN="abort cd cp mysql_dump mysql_backup"


#------------------------------------------------------------------------------
# Abort with error message.
#
# @param abort message
#------------------------------------------------------------------------------
function _abort {
	echo -e "\nABORT: $1\n\n" 1>&2
	exit 1
}


#------------------------------------------------------------------------------
# Change to directory $1. If parameter is empty and _cd was executed before 
# change to last directory.
#
# @param path
# @export LAST_DIR
# @require abort
#------------------------------------------------------------------------------
function _cd {
	LAST_DIR="$PWD"

	if ! test -z "$1"
	then
		if ! test -z "$LAST_DIR"
		then
			_cp "$LAST_DIR"
			return
		else
			_abort "empty directory path"
		fi
	fi

	if ! test -d "$1"; then
		_abort "no such directory [$1]"
	fi

	echo "cd '$1'"
	cd "$1" || _abort "cd '$1' failed"
}


#------------------------------------------------------------------------------
# Copy $1 to $2
#
# @param source path
# @param target path
# @param [md5] if set make md5 file comparison
# @require abort, md5
#------------------------------------------------------------------------------
function _cp {

	local TARGET=`dirname "$2"`

	if ! test -d "$TARGET"; then
		_abort "no such directory [$TARGET]"
	fi

	if test "$3" = "md5" && test -f "$1" && test -f "$2"; then
	  local MD1=`_md5 "$1"`
		local MD2=`_md5 "$2"`

		if test "$MD1" = "$MD2"; then
			echo "Do not overwrite $1 with $2 (same content)"
		else
			echo "Copy file $1 to $2 (update)"
			cp "$1" "$2" || _abort "cp '$1' '$2'"
		fi

		return
  fi

  if test -f "$1"; then
    echo "Copy file $1 to $2"
		cp "$1" "$2" || _abort "cp '$1' '$2'"
	elif test -d "$1"; then
		echo "Copy directory $1 to $2"
		cp -r "$1" "$2" || _abort "cp -r '$1' '$2'"
	else
		_abort "No such file or directory [$1]"
  fi
}


#------------------------------------------------------------------------------
# Create mysql dump. Abort if error.
#
# @param path
# @param options
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# @require abort
#------------------------------------------------------------------------------
function _mysql_dump {

	if test -z "$MYSQL_CONN"; then
		_abort "mysql connection string MYSQL_CONN is empty"
	fi

	echo "mysqldump $2 ... > $1"
	mysqldump $2 $MYSQL_CONN > "$1" || _abort "mysqldump $2 ... > $1 failed"

	if ! test -f "$1"; then
		_abort "no such dump [$1]"
	fi

	local DUMP_OK=`tail -1 "$1" | grep "Dump completed"`
	if test -z "$DUMP_OK"; then
		_abort "invalid mysql dump [$1]"
	fi
}


#------------------------------------------------------------------------------
# Backup mysql database. Run as cron job. Create daily backup.
# Run as cron job, e.g. daily every 1/2 hour
#
# 10 8,9,10,11,12,13,14,15,16,17,18,19,20  * * *  /path/to/mysql_backup.sh
#
# @param backup directory
# @require abort, cd, cp, mysql_dump
#------------------------------------------------------------------------------
function _mysql_backup {

	local LOCK=mysql_backup.lock
	local MIN_SUFFIX=`date +".%H%M.sql"`
	local DAY_SUFFIX=`date +".%Y%m%d.sql"`
	local DUMP="mysql_dump$MIN_SUFFIX"".tar.gz"
	local DAILY_DUMP="mysql_dump$DAY_SUFFIX"".tar.gz"

	if test -f "$LOCK"; then
		_abort "last dump failed or is still running"
	fi

	_cd $1

	echo "update $DUMP and $DAILY_DUMP" > $LOCK
	_mysql_dump "mysql_create$MIN_SUFFIX" "-d"
	_mysql_dump "mysql_insert$MIN_SUFFIX" "--no-create-info=TRUE"

	echo "archive database dump as $DUMP"
	tar -czf "$DUMP" "mysql_create$MIN_SUFFIX" "mysql_insert$MIN_SUFFIX" || _abort "tar -czf '$DUMP' failed"

	_cp "$DUMP" "$DAILY_DUMP"

	# cleanump
	rm "mysql_create$MIN_SUFFIX" "mysql_insert$MIN_SUFFIX" "$LOCK"

	_cd
}


#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

MYSQL_CONN="-h localhost -u DBUSER -pDBPASS DBNAME"

_mysql_backup /path/to/backup/directory

