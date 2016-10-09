#!/bin/bash

#------------------------------------------------------------------------------
# Install composer (getcomposer.org). Use init parameter to install apigen/apigen
# and phpunit/phpunit. Use install if 
#
# @param [|init|remove|install] (optional - default = empty)
#------------------------------------------------------------------------------
function _composer {

	if test "$1" = "remove"; then
		echo "remove composer"
		rm -rf composer.phar vendor composer.lock ~/.composer
	fi

	if ! test -f composer.phar; then
		echo "install composer"
		curl -sS https://getcomposer.org/installer | php
  fi

	if test "$1" = "init"; then
		php composer.phar require --dev apigen/apigen
		php composer.phar require --dev phpunit/phpunit
	fi

	if test "$1" = "install" && test -f composer.json; then
		php composer.phar install
	fi
}

