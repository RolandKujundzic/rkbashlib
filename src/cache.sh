#!/bin/bash

test -z "$CACHE_DIR" && CACHE_DIR="$HOME/.rkbash/cache"
test -z "$CACHE_REF" && CACHE_REF="sh/run ../rkbash/src"
CACHE_OFF=
CACHE=

#--
# Load $1 from cache. If $2 is set update cache value first. Compare last 
# modification of cache file $CACHE_DIR/$1 with sh/run and ../rkbash/src.
# Export CACHE_OFF=1 to disable cache. Disable cache if bash version is 4.3.*.
# Use CACHE_DIR/$1.sh as cache. Use last modification of entries in CACHE_REF
# for cache invalidation.
#
# @param variable name
# @param variable value
# @global CACHE_OFF (default=empty) CACHE_DIR (=$HOME/.rkbash/cache) CACHE_REF (=sh/run ../rkbash/src)
# @export CACHE CACHE_FILE
# @return bool
# shellcheck disable=SC2034
#--
function _cache {
	CACHE_FILE=
	CACHE=

	test -z "$CACHE_OFF" || return 1
	local a key prefix cdir cache_lm entry_lm

	# $1 = abc.xyz.uvw -> prefix=abc key=xyz.uvw
	key="${1#*.}"
	prefix="${1%%.*}"
	cdir="$CACHE_DIR/$prefix"
	test "$prefix" = "$key" && { prefix=""; cdir="$CACHE_DIR"; }

	CACHE_FILE="$cdir/$key"
	_mkdir "$cdir" >/dev/null

	# if pameter $2 is set update CACHE_FILE
	test -z "${2+x}" || echo "$2" > "$CACHE_FILE"

	cache_lm=$(stat -c %Y "$CACHE_FILE" 2>/dev/null)
	test -z "$cache_lm" && return 1

	for a in $CACHE_REF; do
		entry_lm=$(stat -c %Y "$a" 2>/dev/null || _abort "invalid CACHE_REF entry '$a'")
		test "$cache_lm" -lt "$entry_lm" && return 1
	done

	CACHE=$(cat "$CACHE_FILE")
	return 0
}

