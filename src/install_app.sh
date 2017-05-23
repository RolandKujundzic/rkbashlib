#!/bin/bash

#------------------------------------------------------------------------------
# Install files from APP_FILE_LIST and APP_DIR_LIST to APP_PREFIX.
#
# global APP_PREFIX, APP_FILE_LIST, APP_DIR_LIST
# require mkdir cp
#------------------------------------------------------------------------------
function _install_app {

  if ! test -d $APP_PREFIX; then
    _mkdir $APP_PREFIX
  fi

  for FILE in $APP_FILE_LIST
  do
    _mkdir `dirname $APP_PREFIX/$FILE`
    _cp $FILE $APP_PREFIX/$FILE md5
  done

  for DIR in $APP_DIR_LIST
  do
    _mkdir `dirname $APP_PREFIX/$DIR`
    _cp $DIR $APP_PREFIX/$DIR
  done
}

