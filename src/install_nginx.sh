#!/bin/bash

#--
# Install nginx and php-fpm
# shellcheck disable=SC2119
#--
function _install_nginx {
	_apt_update
	_apt_install 'nginx php-fpm'
}
	
