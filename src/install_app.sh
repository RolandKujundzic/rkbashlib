#!/bin/bash

#--
# Install files from APP_FILE_LIST and APP_DIR_LIST to APP_PREFIX.
#
# @param string app dir 
# @param string app url (optional)
# @global APP_PREFIX APP_FILE_LIST APP_DIR_LIST APP_SYNC
#--
function _install_app {
	test -z "$1" && _abort "use _install_app . $2"
	test -z "$2" || _dl_unpack "$1" "$2"

	_require_dir "$1"
	_require_global APP_PREFIX

	_mkdir "$APP_PREFIX"

	local dir file entry

	for dir in $APP_DIR_LIST; do
		_mkdir "$(dirname "$APP_PREFIX/$dir")"
		_cp "$1/$dir" "$APP_PREFIX/$dir"
	done

	for file in $APP_FILE_LIST; do
		_mkdir "$(dirname "$APP_PREFIX/$file")"
		_cp "$1/$file" "$APP_PREFIX/$file" md5
	done

	for entry in $APP_SYNC; do
		_msg "rsync -av '$1/$entry' '$APP_PREFIX'/"
		$SUDO rsync -av "$1/$entry" "$APP_PREFIX"/ >/dev/null 2>/dev/null
	done

	_rm "$1"
}

