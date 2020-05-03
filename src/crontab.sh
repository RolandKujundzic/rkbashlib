#!/bin/bash
	
#--
# Install user ($1) crontab ($2 $3).
#
# @param string user
# @param string repeat-time
# @param string command
#--
function _crontab {
	_msg "install '$1' crontab: [$2 $3] ... " -n
	_require_program crontab
	_mkdir '/var/spool/cron/crontabs' >/dev/null

	test "$(whoami)" = "$1" || _run_as_root

	if crontab -l -u "$1" 2>/dev/null | grep "$3" >/dev/null; then
		_msg "skip (already installed)"
		return
	fi

	if { crontab -l -u "$1" 2>/dev/null; echo "$2 $3"; } | crontab -u "$1" -; then
		_msg "ok"
	else
		_msg "failed"
		_abort "failed to add [$2 $3] to '$1' cron"
	fi
}

