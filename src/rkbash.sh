#!/bin/bash

#--
function __abort {
	echo -e "\nABORT: $1\n\n"
	exit 1
}


#--
# Use for dynamic loading.
# @example _rkbash "_rm _mv _cp _mkdir"
# @global RKBASH_SRC = /path/to/rkbashlib/src
# @param function list
# shellcheck disable=SC1090,SC2086
#--
function _rkbash {
	test -z "$RKBASH_SRC" && RKBASH_SRC=../../rkbashlib/src
	test -d "$RKBASH_SRC" || RKBASH_SRC=../../../rkbashlib/src
	local a abort 

	abort=_abort
	test "$(type -t $abort)" = 'function' || abort=__abort

	[[ -d "$RKBASH_SRC" && -f "$RKBASH_SRC/abort.sh" ]] || \
		$abort "invalid RKBASH_SRC path [$RKBASH_SRC] - $APP_PREFIX $APP"

	for a in $1; do
		if ! test "$(type -t $a)" = "function"; then
			echo "load $a"
			source "$RKBASH_SRC/${a:1}.sh" || $abort "no such function $a"
		else 
			echo "found $a"
		fi
	done
}

