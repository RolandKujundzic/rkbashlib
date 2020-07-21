#!/bin/bash

#--
# Update git components in php/. Flag:
#
# 1: https://github.com/RolandKujundzic/rkphplib.git
#	2: rk@s1.dyn4.com:/data/git/php/phplib.git
# 4: sparse
#
# @param int flag (2^N, default=7)
#--
function _git_update_php {
	local flag
	flag=$((${1:-7} + 0))

	_mkdir php
	_cd php

	if test $((flag & 4)) -eq 4; then
		_require_program rks-git
		test $((flag & 1)) -eq 1 && rks-git clone rkphplib --version=src --q1=y --q2=y
		test $((flag & 2)) -eq 2 && rks-git clone phplib --version=src --q1=y --q2=y
	fi

	test $((flag & 1)) -eq 1 && _git_checkout "https://github.com/RolandKujundzic/rkphplib.git" rkphplib
	test $((flag & 2)) -eq 2 && _git_checkout "rk@s1.dyn4.com:/data/git/php/phplib.git" phplib

	_cd ..
}

