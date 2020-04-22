#!/bin/bash

#--
# Install Amazon AWS PHP SDK.
#--
function _aws {
	_composer
	_composer_pkg aws/aws-sdk-php
}

