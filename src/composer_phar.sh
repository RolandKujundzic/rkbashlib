#!/bin/bash

#--
# Install composer.phar in current directory
#
# @param install_as (default = './composer.phar')
# shellcheck disable=SC2046
#--
function _composer_phar {
	local expected_sig actual_sig install_as sudo result
	expected_sig="$(_wget "https://composer.github.io/installer.sig" -)"
	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	actual_sig="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

  if test "$expected_sig" != "$actual_sig"; then
    _rm composer-setup.php
    _abort 'Invalid installer signature'
  fi

	install_as="$1"
	sudo='sudo'

	if test -z "$install_as"; then
		install_as="./composer.phar"
		sudo=
	fi

  $sudo php composer-setup.php --quiet --install-dir=$(dirname "$install_as") --filename=$(basename "$install_as")
	result=$?

	if ! test "$result" = "0" || ! test -s "$install_as"; then
		_abort "composer installation failed"
	fi

	_rm composer-setup.php
}

