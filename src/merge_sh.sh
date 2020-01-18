#!/bin/bash

#--
# Merge $1_ into $1 (concat $1_/*.inc.sh).
#
# @param string script path
# @require _require_file _require_dir _chmod _md5
#--
function merge_sh {
	_require_file "$1"
	local SH_DIR=`dirname "$1"`'_'
	_require_dir "$DIR"

	local MD5_OLD=`_md5_file "$0"`
  echo -n "merge $SH_DIR into $1 ... "

	local a
	for a in "$SH_DIR"/*.inc.sh; do
		tail -n+2 "$a" >> "$1"
  done

  _chmod 755 "$1"

	local MD5_NEW=`_md5_file "$0"`
	test "$MD5_OLD"="$MD5_NEW" && echo "no change" || echo "update"
}

