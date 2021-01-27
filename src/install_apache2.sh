#!/bin/bash

#--
# Install apache2 and mod php
# shellcheck disable=SC2119
#--
function _install_apache2 {
	_apt_update
	_apt_install "apache2 apache2-utils libapache2-mod-php apache2-mpm-itk"
}
	
