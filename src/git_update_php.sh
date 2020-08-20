#!/bin/bash

#--
# Update git components in php/. Flag:
#
# 1: https://github.com/RolandKujundzic/rkphplib.git
#	2: rk@s1.dyn4.com:/data/git/php/phplib.git
# 4: sparse
# 8: auto-detect if settings.php exists
#
# @param int flag (2^N, default=15)
#--
function _git_update_php {
	local flag version
	flag=$((${1:-7} + 0))

	if [[ $((flag & 8)) -eq 8 && -s settings.php ]]; then
		if test $((flag & 1)) -eq 1 && ! grep -q "__DIR__.'/php/rkphplib/src/" settings.php; then
			flag=$((flag ^ 1))
		fi

		if test $((flag & 2)) -eq 2 && ! grep -q "__DIR__.'/php/phplib/src/" settings.php; then
			flag=$((flag ^ 2))
		fi
	fi

	_mkdir php
	_cd php

	# @ToDo $(_version php 2)
	version=8

	if test $((flag & 4)) -eq 4; then
		_require_program rks-git
		[[ $((flag & 1)) = 1 && ! -d rkphplib ]] && rks-git clone rkphplib --version="$version" --q1=y --q2=y
		[[ $((flag & 2)) = 2 && ! -d phplib ]] && rks-git clone phplib --version="$version" --q1=y --q2=y
	fi

	test $((flag & 1)) -eq 1 && _git_checkout "https://github.com/RolandKujundzic/rkphplib.git" rkphplib
	test $((flag & 2)) -eq 2 && _git_checkout "rk@s1.dyn4.com:/data/git/php/phplib.git" phplib

	_cd ..
}

