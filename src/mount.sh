#!/bin/bash

#--
# Mount $1 (e.g. /dev/sdb2) to $2 (e.g. /mnt)
#
# @param device
# @param directory (mount point)
#--
function _mount {
	local HAS_FS=`file -sL $1 | grep ' filesystem'`
	if test -z "$HAS_FS"; then
		# check if fat32 boot
		HAS_FS=`file -sL $1 | grep 'MBR boot sector'`

		test -z "$HAS_FS" && _abort "no filesystem on $1"
	fi

	local HAS_MOUNT=`mount | grep -E "^$1 on $2"`

	if test -z "$HAS_MOUNT"; then
		HAS_MOUNT=`mount | grep -E "^$1 on "`
		if ! test -z "$HAS_MOUNT"; then
			_confirm "umount $1 (and re-mount as $2)" 1
			test "$CONFIRM" = "y" || _abort "user abort"
			umount /dev/sdb2 || _abort "umount /dev/sdb2"
		fi

		_confirm "Mount $1 as $2"
		if test "$CONFIRM" = "y"; then
			mount $1 "$2" || _abort "mount $1 '$2'"
		fi

		HAS_MOUNT=`mount | grep -E "^$1 on $2"`
		test -z "$HAS_MOUNT" && _abort "failed to mount $1 as $2"
	else
		echo "$1 is already mounted as $2"
	fi
}

