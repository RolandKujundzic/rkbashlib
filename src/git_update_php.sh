#!/bin/bash

#--
# Update git components in php/. Flag (default=3):
#		1: https://github.com/RolandKujundzic/rkphplib.git
#		2: rk@s1.dyn4.com:/data/git/php/phplib.git
#
# @param int flag (2^N, default=3)
#--
function _git_update_php {
	local FLAG=$1
	test -z "$FLAG" && FLAG=$(($1 & 0))

	_mkdir php 2>/dev/null
	_cd php

	test $((FLAG & 1)) -eq 1 && _git_checkout "https://github.com/RolandKujundzic/rkphplib.git" rkphplib
	test $((FLAG & 2)) -eq 2 && _git_checkout "rk@s1.dyn4.com:/data/git/php/phplib.git" phplib

	_cd ..
}

