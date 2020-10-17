#!/bin/bash

#--
# Run make script
# @param check|test|... (optional)
# shellcheck disable=SC2086
#--
function _make {
	local log
	log="$RKBASH_DIR/$(basename "$PWD")/make$1.log"
	_mkdir "$(dirname "$log")" >/dev/null

	SECONDS=0
	_msg "make $1"
	_msg "log: $log"
	make $1 >"$log" 2>&1 || _abort "make $1 >$log 2>&1"
	_msg "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."
}

