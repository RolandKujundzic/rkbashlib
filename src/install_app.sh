#!/bin/bash

#--
# Install files from APP_FILE_LIST and APP_DIR_LIST to APP_PREFIX.
#
# @param string app dir 
# @param string app url (optional)
# @global APP_PREFIX APP_FILE_LIST APP_DIR_LIST APP_SYNC
# @require _abort _mkdir _cp _dl_unpack _rm _require_global _require_dir
#--
function _install_app {
	test -z "$1" && _abort "use _install_app . $2"
	test -z "$2" || _dl_unpack $1 $2

	_require_dir "$1"
	_require_global APP_PREFIX

	test -d $APP_PREFIX || _mkdir $APP_PREFIX

	local dir
	for dir in $APP_DIR_LIST; do
		_mkdir `dirname "$APP_PREFIX/$dir"`
		_cp "$1/$dir" "$APP_PREFIX/$dir"
	done

	local file
	for file in $APP_FILE_LIST; do
		_mkdir `dirname "$APP_PREFIX/$file"`
		_cp "$1/$file" "$APP_PREFIX/$file" md5
	done

	local entry
	for entry in $APP_SYNC; do
		$SUDO rsync -av "$1/$entry" "$APP_PREFIX"/
	done

	_rm "$1"
}

