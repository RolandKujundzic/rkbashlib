#!/bin/bash

#--
# Export required $RKBASH_SRC/src/* functions as $RKBASH_INC
#
# @global RKBASH_SRC (default = .)
# @export RKBASH_INC RKBASH_INC_NUM
# @export_local _HAS_SCRIPT
# @param file path
# shellcheck disable=SC2034,SC2068
#--
function _rkbash_inc {
	local _HAS_SCRIPT
	declare -A _HAS_SCRIPT

	if test -z "$RKBASH_SRC"; then
		if test -s "src/abort.sh"; then
			RKBASH_SRC='src'
		else
			_abort 'set RKBASH_SRC'
		fi
	elif ! test -s "$RKBASH_SRC/abort.sh"; then
		_abort "invalid RKBASH_SRC='$RKBASH_SRC'"
	fi

	test -s "$1" || _abort "no such file '$1'"
	_rrs_scan "$1"

	RKBASH_INC=$(_sort ${!_HAS_SCRIPT[@]})
	RKBASH_INC_NUM="${#_HAS_SCRIPT[@]}"
}


#--
# Export required rkbash/src/* functions as ${!_HAS_SCRIPT[@]}.
#
# @global RKBASH_SRC
# @global_local _HAS_SCRIPT
# @param file path
#--
function _rrs_scan {
	local a func_list
	test -f "$1" || _abort "no such file '$1'"
	func_list=$(grep -E -o -e '(_[a-z0-9\_]+)' "$1" | xargs -n1 | sort -u | xargs)

	for a in $func_list; do
		if [[ -z "${_HAS_SCRIPT[$a]}" && -s "$RKBASH_SRC/${a:1}.sh" ]]; then
			_HAS_SCRIPT[$a]=1
			_rrs_scan "$RKBASH_SRC/${a:1}.sh"
		fi
	done
}

