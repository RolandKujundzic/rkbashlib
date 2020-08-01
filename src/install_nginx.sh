#!/bin/bash

#--
# Install nginx and php-fpm
#--
function _install_nginx {
	_apt_update
	_apt_install 'nginx php-fpm'
}
	
