#!/bin/bash

#--
# Create corodva project in app/ directory.
# 
# @param app name
# shellcheck disable=SC2119
#--
function _cordova_create {
	test -d "app/$1" && _abort "Cordova project app/$1 already exists"
	test -d app || _mkdir app

	_cd app
	cordova create "$1"
	_cd "$1"

	local os_type
	os_type=$(_os_type)

	if "$os_type" = "linux"; then
		_cordova_add_android
		test -d www_src/patch/android || _mkdir www_src/patch/android
		echo -e "PATCH_LIST=\nPATCH_DIR=\n" > www_src/patch/android/patch.sh
	elif "$os_type" = "macos"; then
		_cordova_add_ios
		test -d www_src/patch/ios || _mkdir www_src/patch/ios
		echo -e "PATCH_LIST=\nPATCH_DIR=\n" > www_src/patch/ios/patch.sh
	fi

	_cd ../..
}

