#!/bin/bash

#--
# Merge "$APP"_ (or ../`basename "$APP"`) directory into $APP (concat *.inc.sh).
# Use 0_header.inc.sh, function.inc.sh, ... Z_main.inc.sh.
# 
# @example test.sh, test.sh_/ and test.sh_/*.inc.sh
# @example test.sh/, test.sh/test.sh and test.sh/*.inc.sh
#
# @global APP
# @require _require_file _require_dir _chmod _md5 _rm
# @exit
#--
function _merge_sh {
	_require_file "$APP"
	local SH_DIR="$APP"'_'

	test -d "$SH_DIR" || { test -d `basename $APP` && SH_DIR=`basename $APP`; }

	_require_dir "$SH_DIR"

	local TMP_APP="$SH_DIR"'_'

	local MD5_OLD=`_md5 "$APP"`
  echo -n "merge $SH_DIR into $APP ... "

	echo '#!/bin/bash' > "$TMP_APP"

	local a
	for a in "$SH_DIR"/*.inc.sh; do
		tail -n+2 "$a" >> "$TMP_APP"
  done

	local MD5_NEW=`_md5 "$TMP_APP"`

	if test "$MD5_OLD" = "$MD5_NEW"; then
		echo "no change"
		_rm "$TMP_APP" >/dev/null
	else
		echo "update"
		_mv "$TMP_APP" "$APP"
  	_chmod 755 "$APP"
	fi

	exit 0
}

