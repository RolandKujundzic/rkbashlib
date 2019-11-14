#!/bin/bash

#------------------------------------------------------------------------------
# Change owner and group of path
#
# @param path (if empty use $FOUND)
# @param owner
# @param group 
# @sudo
# @require _abort
#------------------------------------------------------------------------------
function _chown {
	if test -z "$2" || test -z "$3"; then
		_abort "owner [$2] or group [$3] is empty"
	fi

	if test -z "$1"; then
		for ((i = 0; i < ${#FOUND[@]}; i++)); do
			local CURR_OWNER=
			local CURR_GROUP=

			if test -f "${FOUND[$i]}" || test -d "${FOUND[$i]}"; then
				CURR_OWNER=$(stat -c '%U' "${FOUND[$i]}")
				CURR_GROUP=$(stat -c '%G' "${FOUND[$i]}")
			fi

			if test "$CURR_OWNER" != "$2" || test "$CURR_GROUP" != "$3"; then
				_sudo "chown -R '$2.$3' '${FOUND[$i]}'" 1
			fi
		done
	elif test -f "$1"; then
		local CURR_OWNER=$(stat -c '%U' "$1")
		local CURR_GROUP=$(stat -c '%G' "$1")

		if test -z "$CURR_OWNER" || test -z "$CURR_GROUP"; then
			_abort "stat owner [$CURR_OWNER] or group [$CURR_GROUP] of [$1] failed"
		fi

		if test "$CURR_OWNER" != "$2" || test "$CURR_GROUP" != "$3"; then
			_sudo "chown -R '$2.$3' '$1'" 1
		fi
	else
		# no stat compare because subdir entry may have changed
		_sudo "chown -R $2.$3 '$1'" 1
	fi
}

