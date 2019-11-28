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
#--
function _rkscript {

	if test -z "$RKSCRIPT"; then
		RKSCRIPT=../../rkscript/src
	fi

	if ! test -d "$RKSCRIPT"; then
		RKSCRIPT=../../../rkscript/src
	fi

	local ABORT=_abort
	local HAS_ABORT=`type -t $ABORT`
	if ! test "$HAS_ABORT" = "function"; then
		ABORT=__abort
	fi

	if ! test -d "$RKSCRIPT" || ! test -f "$RKSCRIPT/abort.sh"; then
		$ABORT "invalid RKSCRIPT path [$RKSCRIPT] - $APP_PREFIX $APP"
	fi

	for a in $1; do
		local TYPE=`type -t $a`
		if ! test "$TYPE" = "function"; then
			echo "load $a"
			. "$RKSCRIPT/${a:1}.sh" || $ABORT "no such function $a"
		else 
			echo "found $a"
		fi
	done
}

