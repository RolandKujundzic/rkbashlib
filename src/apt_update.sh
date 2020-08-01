#!/bin/bash

#--
# Run apt update (+upgrade). Skip if run within last week.
# @param optional flag: 1 = run upgrade
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
		echo -n "apt -y update ... "
		apt -y update >"$RKBASH_DIR/update.log" 2>&1
		echo "done"

		if test "$1" = 1; then
			echo -n "apt -y upgrade ... "
 			apt -y upgrade >"$RKBASH_DIR/upgrade.log" 2>&1
			echo "done"
		fi
	fi

	_rkbash_dir reset
}

