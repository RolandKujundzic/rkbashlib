#!/bin/bash

#--
# Install php and php packages
#--
function _install_php {
	_apt_update	
  _apt_install 'php-cli php-curl php-mbstring php-gd php-xml php-tcpdf php-json'
  _apt_install 'php-dev php-imap php-xdebug php-pear php-zip php-pclzip'
}

