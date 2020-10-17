#!/bin/bash

#--
# Run make install script
# shellcheck disable=SC2024
#--
function _make_install {
	local log
	log="$RKBASH_DIR/$(basename "$PWD")/make_install.log"
	_mkdir "$(dirname "$log")" >/dev/null

	SECONDS=0
	_msg "sudo make install (see $log)"
	sudo make install >"$log" 2>&1 || _abort "make install >$log 2>&1"
	_msg "$((SECONDS / 60)) minutes and $((SECONDS % 60)) seconds elapsed."
}

