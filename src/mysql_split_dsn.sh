#!/bin/bash

#--
# Split php database connect string settings_dsn. If DB_NAME and DB_PASS are set
# do nothing.
#
# @param php_file (if empty search for docroot with settings.php and|or index.php)
# @param int don't abort (default = 0 = abort)
# @global DOCROOT PATH_RKPHPLIB
# @export DB_NAME (DB_LOGIN) DB_PASS MYSQL DOCROOT
# @return bool
# shellcheck disable=SC2119,SC2120
#--
function _mysql_split_dsn {
	_my_cnf

	[[ -z "$DB_NAME" || -z "$DB_PASS" ]] || return 0

	if ! test -f "$1"; then
		test -z "$DOCROOT" && { _find_docroot "$PWD" "$2" || return 1; }

		if test -f "$DOCROOT/settings.php"; then
			_settings_php "$DOCROOT/settings.php"
		elif test -f "$DOCROOT/index.php"; then
			_settings_php "$DOCROOT/settings.php"
		fi
	else
		_settings_php "$1"
	fi

	[[ -z "$DB_NAME" || -z "$DB_PASS" ]] || return 0

	test -z "$2" && _abort "autodetect DB_NAME|PASS failed"
	return 1
}


#--
# Load settings.php via php and export SETTINGS_(DB_NAME|DB_PASS|DSN), PATH_(RKPHPLIB|PHPLIB) and DOCROOT.
# @param settings.php path
# shellcheck disable=SC2016
#--
function _settings_php {
	local php_code php_out

	IFS='' read -r -d '' php_code <<'EOF'
include(getenv('SETTINGS_PHP'));

if (defined('SETTINGS_DB_NAME') && defined('SETTINGS_DB_PASS') && !empty(SETTINGS_DB_NAME) && !empty(SETTINGS_DB_PASS)) {
	print "DB_NAME='".SETTINGS_DB_NAME."'\nDB_PASS='".SETTINGS_DB_PASS."'";
}
else if (defined('SETTINGS_DSN') && defined('PATH_RKPHPLIB')) {
	require(constant('PATH_RKPHPLIB').'ADatabase.class.php');
	$dsn = \rkphplib\ADatabase::splitDSN(SETTINGS_DSN);
	print "DB_NAME='".$dsn['login']."'\nDB_PASS='".$dsn['password']."'";
	if ($dsn['login'] != $dsn['name']) {
		print "\nDB_LOGIN='".$dsn['login']."'";
	}
}
EOF

	_require_file "$1"
	php_out=$(SETTINGS_PHP="$1" php -r "$php_code")
	test -z "$php_out" || echo "$php_out"
}

