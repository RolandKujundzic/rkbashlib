#!/bin/bash

#------------------------------------------------------------------------------
# Update git components.
#------------------------------------------------------------------------------
function _git_update {
	test -d php || mkdir php
	cd php

	_git_checkout "https://github.com/RolandKujundzic" "rkphplib"
	_git_checkout "rk@s1.dyn4.com:/data/git" "phplib"

	cd ..
}

