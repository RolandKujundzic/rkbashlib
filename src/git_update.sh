#!/bin/bash

#------------------------------------------------------------------------------
# Update git components.
#
# @require _git_checkout _mkdir
#------------------------------------------------------------------------------
function _git_update {
	_mkdir php
	cd php
	_git_checkout "https://github.com/RolandKujundzic/rkphplib.git" rkphplib
	_git_checkout "rk@s1.dyn4.com:/data/git/php/phplib.git" phplib
	cd ..
}

