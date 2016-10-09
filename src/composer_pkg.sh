#!/bin/bash

#------------------------------------------------------------------------------
# Install php package with composer. Target directory is vendor/$1
#
# @param composer-vendor-directory
# @require abort
#------------------------------------------------------------------------------
function _composer_pkg {
	if ! test -f composer.phar; then
		_abort "Install composer first"
	fi

	if test -d "vendor/$1" && test -f composer.json && ! test -z `grep "$1" composer.json`; then
		echo "Update composer package $1 in vendor/" 
		php composer.phar update $1
	else
		echo "Install composer package $1 in vendor/" 
		php composer.phar require $1
	fi
}

