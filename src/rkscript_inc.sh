#!/bin/bash

#--
# Export required $RKSCRIPT_PATH/src/* functions as $REQUIRED_RKSCRIPT.
#
# @global RKSCRIPT_PATH (default = .)
# @export RKSCRIPT_INC RKSCRIPT_INC_NUM
# @export_local _HAS_SCRIPT
# @param file path
#--
function _rkscript_inc {
	local _HAS_SCRIPT
	declare -A _HAS_SCRIPT

	if test -z "$RKSCRIPT_PATH"; then
		test -s "src/abort.sh" && RKSCRIPT_PATH='.' || _abort 'set RKSCRIPT_PATH'
	elif ! test -s "$RKSCRIPT_PATH/src/abort.sh"; then
		_abort "invalid RKSCRIPT_PATH='$RKSCRIPT_PATH'"
	fi

	test -s "$1" || _abort "no such file '$1'"
	_rrs_scan "$1"

	RKSCRIPT_INC=`_sort ${!_HAS_SCRIPT[@]}`
	RKSCRIPT_INC_NUM="${#_HAS_SCRIPT[@]}"
}


#--
# Export required rkscript/src/* functions as ${!_HAS_SCRIPT[@]}.
#
# @global RKSCRIPT_PATH
# @global_local _HAS_SCRIPT
# @param file path
#--
function _rrs_scan {
	test -f "$1" || _abort "no such file '$1'"
	local func_list=`grep -E -o -e '(_[a-z0-9\_]+)' "$1" | xargs -n1 | sort -u | xargs`

	local a
	local b
	for a in $func_list; do
		if [[ -z "${_HAS_SCRIPT[$a]}" && -s "$RKSCRIPT_PATH/src/${a:1}.sh" ]]; then
			_HAS_SCRIPT[$a]=1
			_rrs_scan "$RKSCRIPT_PATH/src/${a:1}.sh"
		fi
	done
}

