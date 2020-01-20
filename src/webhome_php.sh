#!/bin/bash

#--
# Link php/rkphplib to /webhome/.php/rkphplib if $1 & 1=1.
# Link php/phplib to /webhome/.php/phplib if $1 & 2=2.
#
# @param int flag
# @require _mkdir _cd _require_dir
#--
function _webhome_php {
	local FLAG=$1
	local GIT_DIR

	test -z "$FLAG" && FLAG=$(($1 & 0))
	test -z "$CURR" && local CURR=$PWD

	test $((FLAG & 1)) -eq 1 && GIT_DIR=( "rkphplib" )
	test $((FLAG & 2)) -eq 2 && GIT_DIR=( $GIT_DIR "phplib" )

	_mkdir php >/dev/null
	_cd php 

	local i; local dir;
	for ((i = 0; i < ${#GIT_DIR[@]}; i++)); do
 		dir="${GIT_DIR[$i]}"
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

