#!/bin/bash

#--
# Merge "$APP"_ into $APP (concat "$APP""_/*.inc.sh").
#
# @global APP
# @require _require_file _require_dir _chmod _md5
#--
function _merge_sh {
	_require_file "$APP"
	local SH_DIR="$APP"'_'
	_require_dir "$SH_DIR"

	local MD5_OLD=`_md5_file "$APP"`
  echo -n "merge $SH_DIR into $APP ... "

	local a
	for a in "$SH_DIR"/*.inc.sh; do
		tail -n+2 "$a" >> "$APP"
  done

  _chmod 755 "$APP"

	local MD5_NEW=`_md5_file "$APP"`
	test "$MD5_OLD"="$MD5_NEW" && echo "no change" || echo "update"
}

