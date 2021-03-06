#!/bin/bash

#--
# Install php and php packages
# shellcheck disable=SC2119
#--
function _install_php {
	_apt_update	
  _apt_install 'php-cli php-curl php-mbstring php-gd php-xml php-tcpdf php-json'
  _apt_install 'php-dev php-imap php-intl php-xdebug php-pear php-zip php-pclzip'
}

