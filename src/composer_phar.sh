#!/bin/bash

#------------------------------------------------------------------------------
# Install composer.phar in current directory
#
# @param install_as (default = './composer.phar')
# @require _abort _rm _wget
#------------------------------------------------------------------------------
function _composer_phar {
  local EXPECTED_SIGNATURE="$(_wget "https://composer.github.io/installer.sig" -)"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  local ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

  if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
    _rm composer-setup.php
    _abort 'Invalid installer signature'
  fi

	local INSTALL_AS="$1"
	local SUDO=sudo

	if test -z "$INSTALL_AS"; then
		INSTALL_AS="./composer.phar"
		SUDO=
	fi

  $SUDO php composer-setup.php --quiet --install-dir=`dirname "$INSTALL_AS"` --filename=`basename "$INSTALL_AS"`
  local RESULT=$?

	if ! test "$RESULT" = "0" || ! test -s "$INSTALL_AS"; then
		_abort "composer installation failed"
	fi

	_rm composer-setup.php
}

