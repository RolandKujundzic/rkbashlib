#!/bin/bash

#------------------------------------------------------------------------------
# Add ios platform to cordova. If platforms/ios exists do nothing.
# Apply patches from www_src/patch if found.
#------------------------------------------------------------------------------
function _cordova_add_ios {

	test -d platforms/ios && return

	cordova platform add ios

	local PATCH_LIST="MainViewController.m"
	for a in $PATCH_LIST
	do
		local SRC=`find platforms/ios | grep $a`

		if test -f www_src/patch/$a.patch && test -f "$SRC"
		then
			patch $SRC www_src/patch/$a.patch
		fi
	done
}

