#!/bin/bash

#------------------------------------------------------------------------------
# Scan $RKSCRIPT_PATH/src/* directory. Cache result RKSCRIPT_FUNCTIONS.
#
# @export RKSCRIPT_FUNCTIONS 
# @global RKSCRIPT_PATH
# @require _require_global _cd _cache
#------------------------------------------------------------------------------
function _scan_rkscript_src {
	RKSCRIPT_FUNCTIONS=

	local HAS_CACHE=`type -t _cache`

	if test "$HAS_CACHE" = "function"; then
		_cache RKSCRIPT_FUNCTIONS
	fi

	if ! test -z "$RKSCRIPT_FUNCTIONS"; then
		echo "use cached result of _scan_rkscript_src (RKSCRIPT_FUNCTIONS)"
		return
	fi

	_require_global RKSCRIPT_PATH

	local CURR=$PWD
	_cd $RKSCRIPT_PATH/src

	local F=; local a=; local n=0
	for a in *.sh; do
		# negative length doesn't work in OSX bash replace ${a::-3} with ${a:0:${#a}-3}
		F="_"${a:0:${#a}-3}
		RKSCRIPT_FUNCTIONS="$F $RKSCRIPT_FUNCTIONS"
		n=$((n + 1))
	done

	echo "found $n RKSCRIPT_FUNCTIONS"
	_cd $CURR

	if test "$HAS_CACHE" = "function"; then
		_cache RKSCRIPT_FUNCTIONS "$RKSCRIPT_FUNCTIONS"
	fi
}

