#!/bin/bash

#--
# Make directory $1 read|writeable for webserver.
#
# @param directory path
#--
function _webserver_rw_dir {
	_require_dir "$1"
	local me server_user

	if test -s "/etc/apache2/envvars"; then
		server_user=$(grep -E '^export APACHE_RUN_USER=' /etc/apache2/envvars | sed -E 's/.*APACHE_RUN_USER=//')
	fi

	if [[ -n "$server_user" && "$server_user" = "$(stat -c '%U' "$1")" ]]; then
		echo "directory $1 is already owned by webserver $server_user"
		return
	fi

	_msg "find '$1' -type d -exec chmod 770 {} \\;"
	find "$1" -type d -exec chmod 770 {} \;
	_msg "find '$1' -type f -exec chmod 660 {} \\;"
	find "$1" -type f -exec chmod 660 {} \;

	me="$USER"
	test -z "$SUDO_USER" || me="$SUDO_USER"

	_chown "$1" "$me" "$server_user"
}

