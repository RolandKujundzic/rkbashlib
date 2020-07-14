#!/bin/bash

#--
# Install php package with composer. Target directory is vendor/$1
#
# @param composer-vendor-directory
# shellcheck disable=SC2046
#--
function _composer_pkg {
	if ! test -f composer.phar; then
		_abort "Install composer first"
	fi

	if [[ -d "vendor/$1" && -f composer.json ]] && grep -q "$1" 'composer.json'; then
		echo "Update composer package $1 in vendor/"
		php composer.phar update "$1"
	else
		echo "Install composer package $1 in vendor/"
		php composer.phar require "$1"
	fi
}

