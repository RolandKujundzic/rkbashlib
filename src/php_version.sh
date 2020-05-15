#!/bin/bash

#--
# Export PHP_VERSION=MAJOR.MINOR
# 
# @export PHP_VERSION
# shellcheck disable=SC2034
#--
function _php_version {
	PHP_VERSION=$(php -v | grep -E '^PHP [0-9\.]+\-' | sed -E 's/PHP ([0-9]\.[0-9]).+$/\1/')
}

