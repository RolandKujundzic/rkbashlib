#!/bin/bash

#------------------------------------------------------------------------------
# Install files from APP_FILE_LIST and APP_DIR_LIST to APP_PREFIX.
#
# @param string app dir
# @param string app url
# @global APP_PREFIX, APP_FILE_LIST, APP_DIR_LIST
# @require mkdir cp dl_unpack abort md5
#------------------------------------------------------------------------------
function _install_app {

	_dl_unpack $1 $2

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

