#!/bin/bash

#--
# Add ios platform to cordova. If platforms/ios exists do nothing.
# Apply patches from www_src/patch if found.
#
# @param optional action e.g. clean
# @require _rm _os_type _patch
#--
function _cordova_add_ios {
	local OS_TYPE=$(_os_type)

	if test "$OS_TYPE" != "macos"; then
		echo "os type = $OS_TYPE != macos - do not add cordova ios" 
		return
	fi

	if test "$1" = "clean" && test -d platforms/ios; then
		_rm platforms/ios
	fi

	if ! test -d platforms/ios; then
		echo "cordova platform add ios"
		cordova platform add ios
		_patch www_src/patch/ios
	fi
}

