#!/bin/bash
	
#--
# Install user ($1) crontab ($2 $3).
#
# @param string user
# @param string repeat-time
# @param string command
# @require _abort
#--
function _crontab {
	local CRONTAB_DIR="/var/spool/cron/crontabs"
	log "install $1 crontab: $2 $3"
	_mkdir "$CRONTAB_DIR" >/dev/null

	grep "$3" "$CRONTAB_DIR/$1" 2>/dev/null && { echo "already installed - skip"; return; }
	echo "$2 $3" >>"$CRONTAB_DIR/$1" || _abort "failed to create $1 cron"
}

