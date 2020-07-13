#!/bin/bash

#--
# Link php/rkphplib to /webhome/.php/rkphplib if $1 & 1=1.
# Link php/phplib to /webhome/.php/phplib if $1 & 2=2.
#
# @param int flag
# shellcheck disable=SC2128
#--
function _webhome_php {
	local i dir flag git_dir
	flag=$1

	test -z "$flag" && flag=$(($1 & 0))
	test $((flag & 1)) -eq 1 && git_dir=( "rkphplib" )
	test $((flag & 2)) -eq 2 && git_dir=( "$git_dir" "phplib" )

	_mkdir php >/dev/null
	_cd php 

	for ((i = 0; i < ${#git_dir[@]}; i++)); do
 		dir="${git_dir[$i]}"
		_require_dir "/webhome/.php/$dir"

		if test -d "$dir"; then
			_cd "$dir"
			git pull
			_cd ..
		else
			ln -s "/webhome/.php/$dir" "$dir" || _abort "ln -s '/webhome/.php/$dir' '$dir'"
		fi
	done

	_cd ..
}

