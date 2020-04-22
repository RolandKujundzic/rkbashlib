#!/bin/bash
	
#--
# Install user ($1) crontab ($2 $3).
#
# @param string user
# @param string repeat-time
# @param string command
#--
function _crontab {
	local CRONTAB_DIR="/var/spool/cron/crontabs"
	_msg "install '$1' crontab: [$2 $3] ... " -n
	_mkdir "$CRONTAB_DIR" >/dev/null

	_require_program crontab
	{ crontab -l -u "$1" 2>/dev/null | grep "$3" >/dev/null; } && { _msg "skip (already installed)"; return; }
	{ ( crontab -l -u root 2>/dev/null; echo "$2 $3" ) | crontab -u "$1" -; } && _msg "ok" || \
		{ _msg "failed"; _abort "failed to add [$2 $3] to '$1' cron"; }
}

