#!/bin/bash

#------------------------------------------------------------------------------
# Install composer
#------------------------------------------------------------------------------
function _composer {
	echo "Install compser (getcomposer.org)"
	curl -sS https://getcomposer.org/installer | php
}

