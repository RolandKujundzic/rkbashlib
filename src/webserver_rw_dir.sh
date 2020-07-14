#!/bin/bash

#--
# Make directory $1 read|writeable for webserver.
#
# @param directory path
#--
function _webserver_rw_dir {
	test -d "$1" || _abort "no such directory $1"
	local me server_user

	if test -s "/etc/apache2/envvars"; then
		server_user=$(grep -E '^export APACHE_RUN_USER=' /etc/apache2/envvars | sed -E 's/.*APACHE_RUN_USER=//')
	fi

	if [[ -n "$server_user" && "$server_user" = "$(stat -c '%U' "$1")" ]]; then
		echo "directory $1 is already owned by webserver $server_user"
		return
	fi

	_chmod 770 "$1"

	me="$USER"
	test -z "$SUDO_USER" || me="$SUDO_USER"

	_chown "$1" "$me" "$server_user"
}

