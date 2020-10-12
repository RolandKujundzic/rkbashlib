#!/bin/bash

#--
# Install sqlite3 and php-sqlite3
# shellcheck disable=SC2119
#--
function _install_sqlite3 {
	_apt_update
	_apt_install 'sqlite3 php-sqlite3'
}
	
