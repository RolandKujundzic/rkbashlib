#!/bin/bash

#--
# Split php database connect string settings_dsn. If DB_NAME and DB_PASS are set
# do nothing.
#
# @param php_file (if empty search for docroot with settings.php and|or index.php)
# @param int don't abort (default = 0 = abort)
# @global DOCROOT PATH_RKPHPLIB
# @export DB_NAME DB_PASS MYSQL DOCROOT
# @return bool
# shellcheck disable=SC2016
#--
function _mysql_split_dsn {
	local rkphplib settings_dsn php_code split_dsn
	rkphplib="$PATH_RKPHPLIB"

	_my_cnf

	[[ -z "$DB_NAME" || -z "$DB_PASS" ]] || return 0

	if ! test -f "$1"; then
		test -z "$DOCROOT" && { _find_docroot "$PWD" "$2" || return 1; }

		if test -f "$DOCROOT/settings.php"; then
			_mysql_split_dsn "$DOCROOT/settings.php" "$2" && return 0 || return 1
		elif test -f "$DOCROOT/index.php"; then
			_mysql_split_dsn "$DOCROOT/index.php" "$2" && return 0 || return 1
		fi

		test -z "$2" && _abort "no such file [$1]" || return 1
	fi

	php_code='ob_start(); include("'$1'"); $html = ob_get_clean(); if (defined("settings_dsn")) print settings_dsn;'
	settings_dsn=$(php -r "$php_code")

	if test -z "$rkphplib"; then
		php_code='ob_start(); include("'$1'"); $html = ob_get_clean(); if (defined("rkphplib")) print rkphplib;'
		rkphplib=$(php -r "$php_code")
	fi
	
	if test -z "$rkphplib" && test -d "/webhome/.php/rkphplib/src"; then
		rkphplib="/webhome/.php/rkphplib/src/"
	fi

	if test -z "$settings_dsn" && test -f "settings.php"; then
		php_code='ob_start(); include("settings.php"); $html = ob_get_clean(); if (defined("settings_dsn")) print settings_dsn;'
		settings_dsn=$(php -r "$php_code")
		DOCROOT="$PWD"
	fi

	if ! test -z "$DOCROOT" && ! test -z "$rkphplib" && ! test -f "$rkphplib/Exception.class.php" && \
			test -f "$DOCROOT/$rkphplib/Exception.class.php"; then
		rkphplib="$DOCROOT/$rkphplib"
	fi

	if test -z "$settings_dsn"; then
		test -z "$2" && _abort "autodetect settings_dsn failed" || return 1
	fi
 
	if test -z "$rkphplib"; then
		if test -d "$HOME/workspace/rkphplib/src"; then
			rkphplib="$HOME/workspace/rkphplib/src/"
		else
			test -z "$2" && _abort "autodetect rkphplib failed - export rkphplib=/path/to/rkphplib/src/" || return 1
		fi
	fi

	local split_dsn='require("'$rkphplib'ADatabase.class.php"); $dsn = \rkphplib\ADatabase::splitDSN("'$settings_dsn'");'

	php_code=$split_dsn' print $dsn["login"];'
	DB_NAME=$(php -r "$php_code")

	php_code=$split_dsn' print $dsn["password"];'
	DB_PASS=$(php -r "$php_code")

	if test -z "$DB_NAME" || test -z "$DB_PASS"; then
		test -z "$2" && _abort "database name [$DB_NAME] or password [$DB_PASS] is empty" || return 1
	fi
}

