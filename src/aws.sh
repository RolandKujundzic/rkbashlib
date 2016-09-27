#!/bin/bash

#------------------------------------------------------------------------------
# Install Amazon AWS PHP SDK
#------------------------------------------------------------------------------
function _aws {

	if ! test -f composer.phar; then
		_composer
	fi

	echo "Install Amazon AWS PHP SDK with composer" 
	php composer.phar require aws/aws-sdk-php
}

