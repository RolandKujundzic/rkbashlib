#!/bin/bash

#------------------------------------------------------------------------------
# Split php database connect string SETTINGS_DSN. If DB_NAME and DB_PASS are set
# do nothing.
#
# @param php_file (if empty search for docroot with settings.php and|or index.php)
# @export DB_NAME, DB_PASS
# @require _abort _find_docroot 
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
		_find_docroot

		if test -f "$DOCROOT/settings.php"; then
			_mysql_split_dsn settings.php
			return
		elif test -f "$DOCROOT/index.php"; then
			_mysql_split_dsn index.php
			return
		fi

		_abort "no such file [$1]"
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

