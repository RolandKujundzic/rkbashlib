#!/bin/bash

#--
# Split php database connect string SETTINGS_DSN. If DB_NAME and DB_PASS are set
# do nothing.
#
# @param php_file (if empty search for docroot with settings.php and|or index.php)
# @param int don't abort (default = 0 = abort)
# @export DB_NAME DB_PASS MYSQL
# @require _abort _find_docroot _my_cnf 
# @return bool
#--
function _mysql_split_dsn {
	local PATH_RKPHPLIB=$PATH_RKPHPLIB
	local SETTINGS_DSN=
	local PHP_CODE=

	_my_cnf

	if ! test -z "$DB_NAME" && ! test -z "$DB_PASS"; then
		# use already defined DB_NAME and DB_PASS
		return 0
	fi

	if ! test -f "$1"; then
		test -z "$DOCROOT" && { _find_docroot "$PWD" "$2" || return 1; }

		if test -f "$DOCROOT/settings.php"; then
			_mysql_split_dsn "$DOCROOT/settings.php" "$2" && return 0 || return 1
		elif test -f "$DOCROOT/index.php"; then
			_mysql_split_dsn "$DOCROOT/index.php" "$2" && return 0 || return 1
		fi

		test -z "$2" && _abort "no such file [$1]" || return 1
	fi

	PHP_CODE='ob_start(); include("'$1'"); $html = ob_get_clean(); if (defined("SETTINGS_DSN")) print SETTINGS_DSN;'
	SETTINGS_DSN=`php -r "$PHP_CODE"`

	if test -z "$PATH_RKPHPLIB"; then
		PHP_CODE='ob_start(); include("'$1'"); $html = ob_get_clean(); if (defined("PATH_RKPHPLIB")) print PATH_RKPHPLIB;'
		PATH_RKPHPLIB=`php -r "$PHP_CODE"`
	fi
	
	if test -z "$PATH_RKPHPLIB" && test -d "/webhome/.php/rkphplib/src"; then
		PATH_RKPHPLIB="/webhome/.php/rkphplib/src/"
	fi

	if test -z "$SETTINGS_DSN" && test -f "settings.php"; then
		PHP_CODE='ob_start(); include("settings.php"); $html = ob_get_clean(); if (defined("SETTINGS_DSN")) print SETTINGS_DSN;'
		SETTINGS_DSN=`php -r "$PHP_CODE"`
		DOCROOT="$PWD"
	fi

	if ! test -z "$DOCROOT" && ! test -z "$PATH_RKPHPLIB" && ! test -f "$PATH_RKPHPLIB/Exception.class.php" && \
			test -f "$DOCROOT/$PATH_RKPHPLIB/Exception.class.php"; then
		PATH_RKPHPLIB="$DOCROOT/$PATH_RKPHPLIB"
	fi

	if test -z "$SETTINGS_DSN"; then
		test -z "$2" && _abort "autodetect SETTINGS_DSN failed" || return 1
	fi
 
	if test -z "$PATH_RKPHPLIB"; then
		if test -d "/home/rk/Desktop/workspace/rkphplib/src"; then
			PATH_RKPHPLIB="/home/rk/Desktop/workspace/rkphplib/src/"
		else
			test -z "$2" && _abort "autodetect PATH_RKPHPLIB failed - export PATH_RKPHPLIB=/path/to/rkphplib/src/" || return 1
		fi
	fi

	local SPLIT_DSN='require("'$PATH_RKPHPLIB'ADatabase.class.php"); $dsn = \rkphplib\ADatabase::splitDSN("'$SETTINGS_DSN'");'

	PHP_CODE=$SPLIT_DSN' print $dsn["login"];'
	DB_NAME=`php -r "$PHP_CODE"`

	PHP_CODE=$SPLIT_DSN' print $dsn["password"];'
	DB_PASS=`php -r "$PHP_CODE"`

	if test -z "$DB_NAME" || test -z "$DB_PASS"; then
		test -z "$2" && _abort "database name [$DB_NAME] or password [$DB_PASS] is empty" || return 1
	fi
}

