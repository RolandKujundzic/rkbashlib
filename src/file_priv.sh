#!/bin/bash

#--
# Change file privileges for directory (recursiv). 
#
# @param directory
# @param privileges (default 644)
# @param options (default "! -path '.*/' ! -path 'bin/*' ! -name '.*' ! -name '*.sh'")
# shellcheck disable=SC2086
#--
function _file_priv {
	_require_program realpath
	local dir priv msg find_opt

	dir=$(realpath "$1")
	test -d "$dir" || _abort "no such directory [$dir]"

	priv="$2"
	if test -z "$priv"; then
		priv=644
	else
		_is_integer "$priv"
	fi

	msg="chmod $priv files in $1/"

	if test -z "$3"; then
		find_opt="! -path '/.*/' ! -path '/bin/*' ! -name '.*' ! -name '*.sh'"
		msg="$msg ($find_opt)"
	else
		find_opt="$3"
		msg="$msg ($find_opt)"
	fi

	_msg "$msg"
	find "$1" $find_opt -type f -exec chmod $priv {} \; || _abort "find '$1' $find_opt -type f -exec chmod $priv {} \;"
}

