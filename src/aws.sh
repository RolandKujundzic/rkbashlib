#!/bin/bash

#------------------------------------------------------------------------------
# Install Amazon AWS PHP SDK
#
# @require composer, composer_pkg
#------------------------------------------------------------------------------
function _aws {
	_composer
	_composer_pkg aws/aws-sdk-php
}

