#!/bin/bash
MERGE2RUN="abort cd cp create_tgz mysql_dump mysql_backup rm rks-mysql_backup"


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
	echo "cd '$1'"

	if test -z "$1"
	then
		if ! test -z "$LAST_DIR"
		then
			_cd "$LAST_DIR"
			return
		else
			_abort "empty directory path"
		fi
	fi

	if ! test -d "$1"; then
		_abort "no such directory [$1]"
	fi

	LAST_DIR="$PWD"

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
			echo "Do not overwrite $2 with $1 (same content)"
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
# Create tgz archive $1 with files from file/directory list $2.
#
# @param tgz_file
# @param directory/file list
# @require abort
#------------------------------------------------------------------------------
function _create_tgz {

	for a in $2
	do
		if ! test -f $a && ! test -d $a
		then
			_abort "No such file or directory $a"
		fi
	done

	if test -z "$1"; then
		_abort "Empty archive path"
	fi

  echo "create archive $1"
  SECONDS=0
  tar -czf $1 $2 || _abort "tar -czf $1 $2 failed"
  echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."

	tar -tzf $1 > /dev/null || _abort "invalid archive $1" 
}


#------------------------------------------------------------------------------
# Create mysql dump. Abort if error.
#
# @param save_path
# @param options
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# @require abort
#------------------------------------------------------------------------------
function _mysql_dump {

	if test -z "$MYSQL_CONN"; then
		_abort "mysql connection string MYSQL_CONN is empty"
	fi

	echo "mysqldump ... $2 > $1"
	SECONDS=0
	mysqldump $MYSQL_CONN $2 > "$1" || _abort "mysqldump ... $2 > $1 failed"
	echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."

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
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @require abort, cd, cp, mysql_dump, create_tgz, rm
#------------------------------------------------------------------------------
function _mysql_backup {

	local DUMP="mysql_dump."`date +"%H%M"`".tgz"
	local DAILY_DUMP="mysql_dump."`date +"%Y%m%d"`".tgz"
	local FILES="tables.txt"

	if test -f "tables.txt"; then
		_abort "last dump failed or is still running"
	fi

	_cd $1

	echo "update $DUMP and $DAILY_DUMP"

	# dump structure
	echo "create_tables.sql" > tables.txt
	_mysql_dump "create_tables.sql" "-d"
	FILES="$FILES create_tables.sql"

	for T in $(mysql $MYSQL_CONN -e 'show tables' -s --skip-column-names)
	do
		# dump table
		echo "$T" >> tables.txt
		_mysql_dump "$T"".sql" "--extended-insert=FALSE --no-create-info=TRUE $T"
		FILES="$FILES $T"".sql"
	done

	_create_tgz $DUMP "$FILES"
	_cp "$DUMP" "$DAILY_DUMP"
	_rm "$FILES"

	_cd
}


#------------------------------------------------------------------------------
# Remove files/directories.
#
# @param path_list
# @param int (optional - abort if set and path is invalid)
# @require abort
#------------------------------------------------------------------------------
function _rm {

	if test -z "$1"; then
		_abort "Empty remove path list"
	fi

	for a in $1
	do
		if ! test -f $a && ! test -d $a
		then
			if ! test -z "$2"; then
				_abort "No such file or directory $a"
			fi
		else
			echo "remove $a"
			rm -rf $a
		fi
	done
}


#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

MYSQL_CONN="-h localhost -u DBUSER -pDBPASS DBNAME"

_mysql_backup /path/to/backup/directory

