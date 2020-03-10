#!/bin/bash

#--
# Change owner and group of path
#
# @param path (if empty use $FOUND)
# @param owner
# @param group 
# @sudo
# @global CHOWN (default chown -R)
# @require _abort _sudo _require_program _msg
#--
function _chown {
	if test -z "$2" || test -z "$3"; then
		_abort "owner [$2] or group [$3] is empty"
	fi

	_require_program stat

	local CMD="chown -R"
	if ! test -z "$CHOWN"; then
		CMD="$CHOWN"
		CHOWN=
	fi

	local MODIFY=

	if test -z "$1"; then
		for ((i = 0; i < ${#FOUND[@]}; i++)); do
			local CURR_OWNER=
			local CURR_GROUP=

			if test -f "${FOUND[$i]}" || test -d "${FOUND[$i]}"; then
				CURR_OWNER=$(stat -c '%U' "${FOUND[$i]}")
				CURR_GROUP=$(stat -c '%G' "${FOUND[$i]}")
			fi

			if test "$CURR_OWNER" != "$2" || test "$CURR_GROUP" != "$3"; then
				_sudo "$CMD '$2.$3' '${FOUND[$i]}'" 1
			fi
		done
	elif test -f "$1"; then
		local CURR_OWNER=$(stat -c '%U' "$1")
		local CURR_GROUP=$(stat -c '%G' "$1")

		[[ -z "$CURR_OWNER" || -z "$CURR_GROUP" ]] && _abort "stat owner [$CURR_OWNER] or group [$CURR_GROUP] of [$1] failed"
		[[ "$CURR_OWNER" != "$2" || "$CURR_GROUP" != "$3" ]] && MODIFY=1
	elif test -d "$1"; then
		# no stat compare because subdir entry may have changed
		MODIFY=1
	fi

	test -z "$MODIFY" && return

	local ME=`basename "$HOME"`
	if test "$ME" = "$2"; then
		local HAS_GROUP=`groups $ME | grep " $3 "`
		if ! test -z "$HAS_GROUP"; then
			_msg "$CMD $2.$3 '$1'"
			$CMD "$2.$3" "$1" && return
			_msg "$CMD '$2.$3' '$1' failed - try as root"
		fi
	fi

	_sudo "$CMD '$2.$3' '$1'" 1
}

