#!/bin/bash

#--
# Add android platform to cordova. If platforms/android exists do nothing.
# Apply patches from www_src/patch if found.
#
# @param optional action e.g. clean
# shellcheck disable=SC2120
#--
function _cordova_add_android {

	if test "$1" = "clean" && test -d platforms/android; then
		_rm platforms/android
	fi

	if ! test -d platforms/android; then
		echo "cordova platform add android"
		cordova platform add android
		_patch www_src/patch/android
	fi
}

