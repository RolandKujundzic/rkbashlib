#!/bin/bash

#--
# Split php database connect string settings_dsn. If DB_NAME and DB_PASS are set
# do nothing.
#
# @param php_file (if empty search for docroot with settings.php and|or index.php)
# @param int don't abort (default = 0 = abort)
# @global DOCROOT PATH_RKPHPLIB
# @export DB_NAME (DB_USER) DB_PASS MYSQL DOCROOT
# @return bool
# shellcheck disable=SC2119,SC2120
#--
function _mysql_split_dsn {
	_my_cnf

	[[ -n "$DB_NAME" && -n "$DB_PASS" ]] && return 0

	_msd_mysqli

	[[ -n "$DB_NAME" && -n "$DB_PASS" ]] && return 0

	if ! test -f "$1"; then
		test -z "$DOCROOT" && { _find_docroot "$PWD" "$2" || return 1; }

		if test -f "$DOCROOT/settings.php"; then
			_msd_settings_php "$DOCROOT/settings.php"
		elif test -f "$DOCROOT/index.php"; then
			_msd_settings_php "$DOCROOT/settings.php"
		fi
	else
		_msd_settings_php "$1"
	fi

	[[ -z "$DB_NAME" || -z "$DB_PASS" ]] || return 0

	test -z "$2" && _abort "autodetect DB_NAME|PASS failed"
	return 1
}


#--
# Try to detect mysqli://... in *.php
#--
function _msd_mysqli {
	local dsn

	for a in *.php; do
		test -z "$dsn" && dsn=$(grep -E 'define.+SETTINGS_DSN' "$a")
	done

	if [[ -n "$dsn" && "$dsn" =~ mysqli://(.+):(.+)@(.+)/(.+)\'\)\; ]]; then
		if test "${BASH_REMATCH[1]}" = "${BASH_REMATCH[4]}"; then
			DB_NAME="${BASH_REMATCH[1]}"
			DB_PASS="${BASH_REMATCH[2]}"
		fi
	fi
}


#--
# Load settings.php via php and export SETTINGS_(DB_NAME|DB_PASS|DSN), PATH_(RKPHPLIB|PHPLIB) and DOCROOT.
# @param settings.php path
#	@export DB_USER DB_NAME DB_PASS
# shellcheck disable=SC2016,SC2034
#--
function _msd_settings_php {
	local php_code

	IFS='' read -r -d '' php_code <<'EOF'
include(getenv('SETTINGS_PHP'));

if (defined('SETTINGS_DB_NAME') && defined('SETTINGS_DB_PASS')) {
	$login = defined('SETTINGS_DB_USER') ? SETTINGS_DB_USER : SETTINGS_DB_NAME;
	$name= SETTINGS_DB_NAME;
	$pass= SETTINGS_DB_PASS;
}
else if (defined('SETTINGS_DSN') && defined('PATH_RKPHPLIB')) {
	require(constant('PATH_RKPHPLIB').'ADatabase.class.php');
	$dsn = \rkphplib\ADatabase::splitDSN(SETTINGS_DSN);
	$login = $dsn['login'];
	$name = $dsn['name'];
	$pass = $dsn['password'];
}

if (!empty($name) && !empty($login) && !empty($pass)) {
	print "$login\n$name\n$pass";
}
EOF

	_require_file "$1"
	read -r -d "\n" DB_USER DB_NAME DB_PASS <<<"$(SETTINGS_PHP="$1" php -r "$php_code")"
}

