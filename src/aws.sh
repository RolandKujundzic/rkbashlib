#!/bin/bash

#--
# Install Amazon AWS PHP SDK.
# shellcheck disable=SC2119
#--
function _aws {
	_composer
	_composer_pkg aws/aws-sdk-php
}

