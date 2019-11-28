#!/bin/bash

#--
# Patch either PATCH_LIST and PATCH_DIR are set or $1/patch.sh exists.
# If $1/patch.sh exists it must export PATCH_LIST and PATCH_DIR.
# Apply patch if target file and patch file exist.
#
# @param patch file directory
# @require _abort
#--
function _patch {

	if test -f "$1/patch.sh"; then
		. $1/patch.sh
	fi

	local a=; for a in $PATCH_LIST
  do
    local SRC=`find $PATCH_DIR | grep $a`

    if test -f $1/$a.patch && test -f "$SRC"
    then
			echo "patch $SRC $1/$a.patch"
      patch $SRC $1/$a.patch || _abort "patch failed"
    fi
  done
}

