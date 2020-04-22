#!/bin/bash

#--
# Make directory $1 read|writeable for webserver.
#
# @param directory path
#--
function _webserver_rw_dir {
	test -d "$1" || _abort "no such directory $1"

	local DIR_OWNER=`stat -c '%U' "$1"`
	local SERVER_USER=

	if test -s "/etc/apache2/envvars"; then
		SERVER_USER=`cat /etc/apache2/envvars | grep -E '^export APACHE_RUN_USER=' | sed -E 's/.*APACHE_RUN_USER=//'`
	fi

	if ! test -z "$SERVER_USER" && test "$SERVER_USER" = "$DIR_OWNER"; then
		echo "directory $1 is already owned by webserver $SERVER_USER"
		return
	fi

	_chmod 770 "$1"

	local ME="$USER"
	test -z "$SUDO_USER" || ME="$SUDO_USER"

	_chown "$1" "$ME" "$SERVER_USER"
}

