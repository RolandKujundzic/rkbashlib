#!/bin/bash

#--
# Mount $1 (e.g. /dev/sdb2) to $2 (e.g. /mnt)
#
# @param device
# @param directory (mount point)
# shellcheck disable=SC2086,SC2143
#--
function _mount {
	[[ -z "$(file -sL $1 | grep ' filesystem')" && -z "$(file -sL $1 | grep 'MBR boot sector')" ]] && \
		_abort "no filesystem on $1"

	if test -z "$(mount | grep -E "^$1 on $2")"; then
		if ! test -z "$(mount | grep -E "^$1 on ")"; then
			_confirm "umount $1 (and re-mount as $2)" 1
			test "$CONFIRM" = "y" || _abort "user abort"
			umount /dev/sdb2 || _abort "umount /dev/sdb2"
		fi

		_confirm "Mount $1 as $2"
		if test "$CONFIRM" = "y"; then
			mount $1 "$2" || _abort "mount $1 '$2'"
		fi

		test -z "$(mount | grep -E "^$1 on $2")" && _abort "failed to mount $1 as $2"
	else
		echo "$1 is already mounted as $2"
	fi
}

