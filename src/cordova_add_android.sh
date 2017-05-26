#!/bin/bash

#------------------------------------------------------------------------------
# Add android platform to cordova. If platforms/android exists do nothing.
# Apply patches from www_src/patch if found.
#
# @param optional action e.g. clean
# @require rm os_type patch
#------------------------------------------------------------------------------
function _cordova_add_android {

  local OS_TYPE=$(_os_type)

  if "$OS_TYPE" != "macos"; then
		echo "os type = $OS_TYPE != macos - do not add cordova android" 
  fi

	if test "$1" = "clean" && test -d platforms/android; then
		_rm platforms/android
	fi

	if ! test -d platforms/android; then
		echo "cordova platform add android"
		cordova platform add android
		_patch www_src/patch/android
	fi
}

