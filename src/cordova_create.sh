#!/bin/bash

#------------------------------------------------------------------------------
# Create corodva project in app/ directory.
# 
# @param app name
# @require abort os_type cordova_add_android cordova_add_ios patch mkdir
#------------------------------------------------------------------------------
function _cordova_create {
	if test -d "app/$1"; then
		_abort "Cordova project app/$1 already exists"
	fi

	test -d app || _mkdir app

	cd app
	cordova create $1
	cd $1

	local OS_TYPE=$(_os_type)

	if "$OS_TYPE" = "linux"; then
		_cordova_add_android
		test -d www_src/patch/android || _mkdir www_src/patch/android
		echo -e "PATCH_LIST=\nPATCH_DIR=\n" > www_src/patch/android/patch.sh
	elif "$OS_TYPE" = "macos"; then
		_cordova_add_ios
		test -d www_src/patch/ios || _mkdir www_src/patch/ios
		echo -e "PATCH_LIST=\nPATCH_DIR=\n" > www_src/patch/ios/patch.sh
	fi

	cd ../..
}

