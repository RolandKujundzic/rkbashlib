#!/bin/bash

#------------------------------------------------------------------------------
# Patch if $1/patch.sh exists. Example patch.sh:
#
# PATCH_LIST=MainViewController.m
# PATCH_DIR=platforms/ios
#
# @param directory path
# @require _abort
#------------------------------------------------------------------------------
function _patch {

	if ! test -f "$1/patch.sh"; then
		return
	fi

	. $1/patch.sh

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

