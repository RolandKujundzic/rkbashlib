#!/bin/bash

#--
# Change directory privileges (recursive).
#
# @param directory
# @param privileges (default 755)
# @param options (default "! -path '/.*/'")
# shellcheck disable=SC2086
#--
function _dir_priv {
	_require_program realpath

	local dir priv msg find_opt

	dir=$(realpath "$1")
	test -d "$dir" || _abort "no such directory [$dir]"

	priv="$2"
	if test -z "$priv"; then
		priv=755
	else
		_is_integer "$priv"
	fi

	msg="chmod $priv directories in $1/"

	if test -z "$3"; then
    find_opt="! -path '/.*/'"
    msg="$msg ($find_opt)"
	else
    find_opt="$3"
    msg="$msg ($find_opt)"	
  fi

	_msg "$msg"
	find "$1" $find_opt -type d -exec chmod $priv {} \; || _abort "find '$1' $find_opt -type d -exec chmod $priv {} \;"
}

