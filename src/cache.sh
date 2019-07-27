#!/bin/bash

#------------------------------------------------------------------------------
# Load $1 from cache. If $2 is set update cache value first. Compare last 
# modification of cache file .cache/$1 with sh/run and ../rkscript/src.
#
# @param variable name
# @param variable value
# @require _mkdir
#------------------------------------------------------------------------------
function _cache {

	_mkdir .cache

	if ! test -z "$2"; then
		# update cache value - ${2@Q} = escaped value of $2
		echo "$1=${2@Q}" > ".cache/$1"
		echo "update cached value of $1 (.cache/$1)"
	fi

	if test -f ".cache/$1" && test -d "sh/run" && test -d "../rkscript/src"; then
		# last modification unix ts local source
		local SH_LM=`stat -c %Y sh/run`
		# last modification unix ts include source
		local SRC_LM=`stat -c %Y ../rkscript/src`
		# last modification of cache
		local CACHE_LM=`stat -c %Y ".cache/$1"`

		if test $SH_LM -lt $CACHE_LM && test $SRC_LM -lt $CACHE_LM; then
			. ".cache/$1"
			echo "use cached value of $1"
		fi
	fi
}

