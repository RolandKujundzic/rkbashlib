#!/bin/bash

#------------------------------------------------------------------------------
# Install files from APP_FILE_LIST and APP_DIR_LIST to APP_PREFIX.
#
# @param string app dir 
# @param string app url (optional)
# @global APP_PREFIX APP_FILE_LIST APP_DIR_LIST
# @require mkdir cp dl_unpack abort md5 rm require_global
#------------------------------------------------------------------------------
function _install_app {

	if test -z "$1"; then
		_abort "use _install_app . $2"
	fi

	if ! test -z "$2"; then 
		_require_global "APP_PREFIX APP_FILE_LIST APP_DIR_LIST"
		_dl_unpack $1 $2
	fi

  if ! test -d $APP_PREFIX; then
    _mkdir $APP_PREFIX
  fi

  for FILE in $APP_FILE_LIST
  do
    _mkdir `dirname $APP_PREFIX/$FILE`
    _cp $1/$FILE $APP_PREFIX/$FILE md5
  done

  for DIR in $APP_DIR_LIST
  do
    _mkdir `dirname $APP_PREFIX/$DIR`
    _cp $1/$DIR $APP_PREFIX/$DIR
  done

	_rm $1
}

