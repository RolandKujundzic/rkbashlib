#!/bin/bash

#------------------------------------------------------------------------------
# Load $1 from cache. If $2 is set update cache value first. Compare last 
# modification of cache file .rkscript/cache/$1 with sh/run and ../rkscript/src.
# Export CACHE_OFF=1 to disable cache. Disable cache if bash version is 4.3.*.
#
# @param variable name
# @param variable value
# @require _mkdir
#------------------------------------------------------------------------------
function _cache {
	test -z "$CACHE_OFF" || return

	# bash 4.3.* does not support ${2@Q} expression
	local BASH43=`/bin/bash --version | grep 'ersion 4.3.'`
	test -z "$BASH43" || return

	# bash 3.* does not support ${2@Q} expression
	local BASH3X=`/bin/bash --version | grep 'ersion 3.'`
	test -z "$BASH3X" || return

	_mkdir ".rkscript/cache"

	local CACHE=".rkscript/cache/$1.sh"

	if ! test -z "$2"; then
		# update cache value - ${2@Q} = escaped value of $2
		echo "$1=${2@Q}" > "$CACHE"
		echo "update cached value of $1 ($CACHE)"
	fi

	if test -f "$CACHE" && test -d "sh/run" && test -d "../rkscript/src"; then
		# last modification unix ts local source
		local SH_LM=`stat -c %Y sh/run`
		# last modification unix ts include source
		local SRC_LM=`stat -c %Y ../rkscript/src`
		# last modification of cache
		local CACHE_LM=`stat -c %Y "$CACHE"`

		if test $SH_LM -lt $CACHE_LM && test $SRC_LM -lt $CACHE_LM; then
			. "$CACHE"
			echo "use cached value of $1 ($CACHE)"
		fi
	fi
}

