#!/bin/bash

#--
# Rsync $1 to $2. Apply rsync parameter $3 if set (e.g. --delete).
#
# @param source path e.g. user@host:/path/to/source
# @param target path default=[.]
# @param optional rsync parameter e.g. "--delete --exclude /data"
#--
function _rsync {
	local target="$2"
	test -z "$target" && target="."

	test -z "$1" && _abort "Empty rsync source"
	test -d "$target" || _abort "No such directory [$target]"

	local rsync="rsync -av $3 -e ssh '$1' '$2'"
	local error
	_log "$rsync" rsync
	eval "$rsync ${LOG_CMD[rsync]}" || error=1

	if test "$error" = "1"; then
		local sync_finished
		sync_finished=$(tail -4 "${LOG_FILE[rsync]}" | grep 'speedup is ')
		test -z "$sync_finished" && _abort "$rsync"
	fi
}

