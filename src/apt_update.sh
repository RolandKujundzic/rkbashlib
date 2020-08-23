#!/bin/bash

#--
# Run apt update (+upgrade). Skip if run within last week.
# @param optional flag: 1 = run upgrade
# shellcheck disable=SC2024,SC2120
#--
function _apt_update {
	_require_program apt
	local lu now

	_rkbash_dir apt
	lu="$RKBASH_DIR/last_update"
	now=$(date +%s)

	if [[ -f "$lu" && $(cat "$lu") -gt $((now - 3600 * 24 * 7)) ]]; then
		:
	else
		echo "$now" > "$lu" 

		_run_as_root 1
		_msg "apt -y update &>$RKBASH_DIR/update.log ... " -n
		sudo apt -y update &>"$RKBASH_DIR/update.log" || _abort 'sudo apt -y update'
		_msg "done"

		if test "$1" = 1; then
			_msg "apt -y upgrade &>$RKBASH_DIR/upgrade.log  ... " -n
 			sudo apt -y upgrade &>"$RKBASH_DIR/upgrade.log" || _abort 'sudo apt -y upgrade'
			_msg "done"
		fi
	fi

	_rkbash_dir reset
}

