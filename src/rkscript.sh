#!/bin/bash

#--
function __abort {
	echo -e "\nABORT: $1\n\n"
	exit 1
}


#--
# Use for dynamic loading.
# @example _rkscript "_rm _mv _cp _mkdir"
# @global RKSCRIPT = /path/to/rkscript/src
# @param function list
# shellcheck disable=SC1090,SC2086
#--
function _rkscript {
	test -z "$RKSCRIPT" && RKSCRIPT=../../rkscript/src
	test -d "$RKSCRIPT" || RKSCRIPT=../../../rkscript/src
	local a abort 

	abort=_abort
	test "$(type -t $abort)" = 'function' || abort=__abort

	[[ -d "$RKSCRIPT" && -f "$RKSCRIPT/abort.sh" ]] || \
		$abort "invalid RKSCRIPT path [$RKSCRIPT] - $APP_PREFIX $APP"

	for a in $1; do
		if ! test "$(type -t $a)" = "function"; then
			echo "load $a"
			source "$RKSCRIPT/${a:1}.sh" || $abort "no such function $a"
		else 
			echo "found $a"
		fi
	done
}

