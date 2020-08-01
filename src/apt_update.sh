#!/bin/bash

#--
# Run apt update (+upgrade). Skip if run within last week.
# @param optional flag: 1 = run upgrade
# shellcheck disable=SC2024
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
		echo -n "apt -y update &>$RKBASH_DIR/update.log ... "
		sudo apt -y update &>"$RKBASH_DIR/update.log" || _abort 'sudo apt -y update'
		echo "done"

		if test "$1" = 1; then
			echo -n "apt -y upgrade &>$RKBASH_DIR/upgrade.log  ... "
 			sudo apt -y upgrade &>"$RKBASH_DIR/upgrade.log" || _abort 'sudo apt -y upgrade'
			echo "done"
		fi
	fi

	_rkbash_dir reset
}

