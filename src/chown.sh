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

	local cmd="chown -R"
	if ! test -z "$CHOWN"; then
		cmd="$CHOWN"
		CHOWN=
	fi

	local modify

	if test -z "$1"; then
		for ((i = 0; i < ${#FOUND[@]}; i++)); do
			local curr_owner=
			local curr_group=

			if test -f "${FOUND[$i]}" || test -d "${FOUND[$i]}"; then
				curr_owner=$(stat -c '%U' "${FOUND[$i]}")
				curr_group=$(stat -c '%G' "${FOUND[$i]}")
			fi

			if test "$curr_owner" != "$2" || test "$curr_group" != "$3"; then
				_sudo "$cmd '$2.$3' '${FOUND[$i]}'" 1
			fi
		done
	elif test -f "$1"; then
		local curr_owner=$(stat -c '%U' "$1")
		local curr_group=$(stat -c '%G' "$1")

		[[ -z "$curr_owner" || -z "$curr_group" ]] && _abort "stat owner [$curr_owner] or group [$curr_group] of [$1] failed"
		[[ "$curr_owner" != "$2" || "$curr_group" != "$3" ]] && modify=1
	elif test -d "$1"; then
		# no stat compare because subdir entry may have changed
		modify=1
	fi

	test -z "$modify" && return

	local me=`basename "$HOME"`
	if test "$me" = "$2"; then
		local has_group=`groups $me | grep " $3 "`
		if ! test -z "$has_group"; then
			_msg "$cmd $2.$3 '$1'"
			$cmd "$2.$3" "$1" 2>/dev/null && return
			_msg "$cmd '$2.$3' '$1' failed - try as root"
		fi
	fi

	_sudo "$cmd '$2.$3' '$1'" 1
}

