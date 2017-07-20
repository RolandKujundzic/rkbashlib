#!/bin/bash
MERGE2RUN="copyright abort syntax mysql_create_db mysql_split_dsn rks-mysql_create"


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
# Abort with SYNTAX: message.
# Usually APP=$0
#
# @global APP, APP_DESC
# @param message
#------------------------------------------------------------------------------
function _syntax {
	echo -e "\nSYNTAX: $APP $1\n" 1>&2

	if ! test -z "$APP_DESC"; then
		echo -e "$APP_DESC\n\n" 1>&2
	else
		echo 1>&2
	fi

	exit 1
}


#------------------------------------------------------------------------------
# Create Mysql Database and user. Define MYSQL="mysql -u root" if not set 
# and user is root. If dbname and password are empty try to autodetect from 
# settings.php or index.php.
#
# @param dbname = username
# @param password
# @export DB_NAME, DB_PASS
# @require abort mysql_split_dsn
#------------------------------------------------------------------------------
function _mysql_create_db {
	DB_NAME=$1
	DB_PASS=$2

	_mysql_split_dsn

	local HAS_DB=`echo "SHOW CREATE DATABASE $DB_NAME" | $MYSQL 2> /dev/null && echo "ok"`
	if ! test -z "$HAS_DB"; then
		echo "Keep existing database $DB_NAME"
		return
	fi

	if test -z "$MYSQL"; then
		if test "$UID" = "0"; then
			MYSQL="mysql -u root"
		else
			_abort "you must be root to run [mysql -u root]"
		fi
	fi

	echo "create mysql database $DB_NAME"
	echo "CREATE DATABASE $DB_NAME" | $MYSQL || _abort "create database $DB_NAME failed"
	echo "create mysql database user $DB_NAME"
	echo "GRANT ALL ON $DB_NAME.* TO '$DB_NAME'@'localhost' IDENTIFIED BY '$DB_PASS'" | $MYSQL || \
		_abort "create database user $DB_NAME failed"
}


#------------------------------------------------------------------------------
# Split php database connect string SETTINGS_DSN. If DB_NAME and DB_PASS are set
# do nothing.
#
# @param php_file (if empty try settings.php, index.php)
# @export DB_NAME, DB_PASS
# @require abort
#------------------------------------------------------------------------------
function _mysql_split_dsn {
	local SETTINGS_DSN=
	local PATH_RKPHPLIB=
	local PHP_CODE=

	if ! test -z "$DB_NAME" && ! test -z "$DB_PASS"
	then
		# use already defined DB_NAME and DB_PASS
		return
	fi

	if ! test -f "$1"; then

		if test -z "$DB_NAME" && test -z "$DB_PASS"
		then
			if test -f 'settings.php'; then
				_mysql_split_dsn settings.php
				return
			elif test -f 'index.php'; then
				_mysql_split_dsn index.php
				return
			else
				_abort "no such file [$1]"
			fi
		fi

	fi

	PHP_CODE='ob_start(); include("'$1'"); $html = ob_get_clean(); if (defined("SETTINGS_DSN")) print SETTINGS_DSN;'
	SETTINGS_DSN=`php -r "$PHP_CODE"`

	PHP_CODE='ob_start(); include("'$1'"); $html = ob_get_clean(); if (defined("PATH_RKPHPLIB")) print PATH_RKPHPLIB;'
	PATH_RKPHPLIB=`php -r "$PHP_CODE"`
		
	if test -z "$SETTINGS_DSN"; then
		_abort "autodetect SETTINGS_DSN failed"
	fi
 
	if test -z "$PATH_RKPHPLIB"; then
		_abort "autodetect PATH_RKPHPLIB failed"
	fi

	local SPLIT_DSN='require("'$PATH_RKPHPLIB'ADatabase.class.php"); $dsn = \rkphplib\ADatabase::splitDSN("'$SETTINGS_DSN'");'

	PHP_CODE=$SPLIT_DSN' print $dsn["login"];'
	DB_NAME=`php -r "$PHP_CODE"`

	PHP_CODE=$SPLIT_DSN' print $dsn["password"];'
	DB_PASS=`php -r "$PHP_CODE"`

	if test -z "$DB_NAME" || test -z "$DB_PASS"; then
		_abort "database name [$DB_NAME] or password [$DB_PASS] is empty"
	fi
}


#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

APP=$0
APP_DESC="Create mysql database and user (dblogin = dbname)"

if ! test -z "$1" && ! test -z "$2"; then
  _mysql_create_db $1 $2
elif test -f settings.php || test -f index.php; then
  _mysql_create_db
else
  _syntax "name password"
fi
