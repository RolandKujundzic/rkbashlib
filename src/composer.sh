#!/bin/bash

#------------------------------------------------------------------------------
# Install composer (getcomposer.org)
#
# @param install_dir (optional)
#------------------------------------------------------------------------------
function _composer {

	local INSTALL_DIR=.
	local CURR=$PWD

	if ! test -z "$1" && test -d "$1"; then
		INSTALL_DIR=$1
	fi

  if test -f "$INSTALL_DIR/composer.phar"; then
		return
  fi

	echo "Install compser in $INSTALL_DIR"
	cd $INSTALL_DIR
	curl -sS https://getcomposer.org/installer | php
	cd $CURR
}

