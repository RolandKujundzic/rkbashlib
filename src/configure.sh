#!/bin/bash

#--
# Run configure script
# @param *
# shellcheck disable=SC2086,SC2048
#--
function _configure {
	local log
	log="$RKBASH_DIR/$(basename "$PWD")/configure.log"
	_mkdir "$(dirname "$log")" >/dev/null

	SECONDS=0
	_msg "./configure $*"
	_msg "log: $log"
	./configure $* >"$log" 2>&1 || _abort "./configure $* >$log 2>&1"
	_msg "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."
}

