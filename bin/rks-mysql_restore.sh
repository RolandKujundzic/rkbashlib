#!/bin/bash
MERGE2RUN="copyright abort extract_tgz cd cp rm mkdir mv mysql_load mysql_restore rks-mysql_restore"


#
# Copyright (c) 2017 Roland Kujundzic <roland@kujundzic.de>
#


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
# Extract tgz archive $1. If second parameter is existing directory, remove
# before extraction.
#
# @param tgz_file
# @param path (optional - if set check if path was created)
# @require abort, rm
#------------------------------------------------------------------------------
function _extract_tgz {

	if ! test -f "$1"; then
		_abort "Invalid archive path [$1]"
	fi

	if [ ! -z "$2" && -d $2 ]; then
		_rm "$2"
	fi

  echo "extract archive $1"
  SECONDS=0
  tar -xzf $1 || _abort "tar -xzf $1 failed"
  echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."

	tar -tzf $1 > /dev/null || _abort "invalid archive $1" 

	if [ ! -z "$2" && [ ! -d "$2" || ! -f "$2"]]; then
		_abort "Path $2 was not created"
	fi
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
# Create directory (including parent directories) if directory does not exists.
#
# @param path
# @param abort_if_exists (optional - if set abort if directory already exists)
# @require abort
#------------------------------------------------------------------------------
function _mkdir {

	if test -z "$1"; then	
		_abort "Empty directory path"
	fi

	if ! test -d "$1"; then
		echo "mkdir -p $1"
		mkdir -p $1 || _abort "mkdir -p '$1'"
	else
		if test -z "$2"
		then
			echo "directory $1 already exists"
		else
			_abort "directory $1 already exists"
		fi
	fi
}


#------------------------------------------------------------------------------
# Move files/directories. Target path directory must exist.
#
# @param source_path
# @param target_path
# @require abort
#------------------------------------------------------------------------------
function _mv {

	if test -z "$1"; then
		_abort "Empty source path"
	fi

	if test -z "$2"; then
		_abort "Empty target path"
	fi

	local PDIR=`dirname "$2"`
	if ! test -d "$PDIR"; then
		_abort "No such directory [$PDIR]"
	fi

	echo "mv '$1' '$2'"
	mv "$1" "$2" || _abort "mv '$1' '$2' failed"
}


#------------------------------------------------------------------------------
# Load mysql dump. Abort if error.
#
# @param dump_file
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @abort
# @require abort
#------------------------------------------------------------------------------
function _mysql_load {

	if test -z "$MYSQL_CONN"; then
		_abort "mysql connection string MYSQL_CONN is empty"
	fi

	if ! test -f "$1"; then
		_abort "no such mysql dump [$1]"
	fi

	local DUMP_OK=`tail -1 "$1" | grep "Dump completed"`
	if test -z "$DUMP_OK"; then
		_abort "invalid mysql dump [$1]"
	fi

	echo "mysql ... < $1"
	SECONDS=0
	mysql $MYSQL_CONN < "$1" || _abort "mysql ... < $1 failed"
	echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed."
}


#------------------------------------------------------------------------------
# Restore mysql database. Use mysql_dump.TS.tgz created with mysql_backup.
#
# @param dump_archive
# @global MYSQL_CONN mysql connection string "-h DBHOST -u DBUSER -pDBPASS DBNAME"
# @require abort, extract_tgz, cd, cp, rm, mv, mkdir, mysql_load
#------------------------------------------------------------------------------
function _mysql_restore {

	local TMP_DIR="/tmp/mysql_dump"
	local FILE=`basename $1`

	_mkdir $TMP_DIR 1
	_cp "$1" "$TMP_DIR/$FILE"

	_cd $TMP_DIR

	_extract_tgz "$FILE" "tables.txt"

	cat create_tables.sql | sed -e 's/ datetime .*DEFAULT CURRENT_TIMESTAMP,/ timestamp,/g' > create_tables.fix.sql
	local IS_DIFFERENT=`cmp -b create_tables.sql create_tables.fix.sql`

	if ! test -z "$IS_DIFFERENT"; then
		_mv create_tables.fix.sql create_tables.sql
	fi

	for a in `cat tables.txt`
	do
		_mysql_load $a
	done

	_cd
	_rm $TMP_DIR
}


#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

MYSQL_CONN="-h localhost -u DBUSER -pDBPASS DBNAME"

_mysql_restore /path/to/mysql_dump.sql

