#!/bin/bash

#------------------------------------------------------------------------------
# Rsync $1 to $2. Apply rsync parameter $3 if set (e.g. --delete).
#
# @param source path e.g. user@host:/path/to/source
# @param target path default=[.]
# @param optional rsync parameter e.g. "--delete --exclude /data"
# @require _abort _log
#------------------------------------------------------------------------------
function _rsync {
	local TARGET="$2"

	if test -z "$TARGET"; then
		TARGET="."
	fi

	if test -z "$1"; then
		_abort "Empty rsync source"
	fi

	if ! test -d "$TARGET"; then
		_abort "No such directory [$TARGET]"
	fi

	local RSYNC="rsync -av $3 -e ssh '$1' '$2'"; local error=
	_log "$RSYNC" rsync
	eval "$RSYNC ${LOG_CMD[rsync]}" || error=1

	if test "$error" = "1"; then
		local sync_finished=`tail -4 ${LOG_FILE[rsync]} | grep 'speedup is '`

		if test -z "$sync_finished"; then
			_abort "$RSYNC"
		fi
	fi
}

