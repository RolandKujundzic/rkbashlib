#!/bin/bash

#--
# Merge "$APP"_ (or ../`basename "$APP"`) directory into $APP (concat *.inc.sh).
# Use 0_header.inc.sh, function.inc.sh, ... Z_main.inc.sh.
# 
# @example test.sh, test.sh_/ and test.sh_/*.inc.sh
# @example test.sh/, test.sh/test.sh and test.sh/*.inc.sh
#
# @global APP
# @param split dir (optional if $APP is used)
# @param output file (optional if $APP is used)
# @exit unless $2 is empty
#--
function _merge_sh {
	local MAPP="${1:-$APP}"

	if ! test -z "$2"; then
		MAPP="$2"
		SH_DIR="$1"
	else
		_require_file "$MAPP"
		local SH_DIR="$MAPP"'_'
		test -d "$SH_DIR" || { test -d `basename $MAPP` && SH_DIR=`basename $MAPP`; }
	fi

	_require_dir "$SH_DIR"

	local TMP_APP="$SH_DIR"'_'
	local MD5_OLD=
	test -s "$MAPP" && MD5_OLD=`_md5 "$MAPP"`
	echo -n "merge $SH_DIR into $MAPP ... "

	echo '#!/bin/bash' > "$TMP_APP"

	local INC_SH=`ls "$SH_DIR"/*.inc.sh "$SH_DIR"/*/*.inc.sh "$SH_DIR"/*/*/*.inc.sh 2>/dev/null | sort`
	local a
	for a in $INC_SH; do
		tail -n+2 "$a" >> "$TMP_APP"
	done

	_add_abort_linenum "$TMP_APP"

	local MD5_NEW=`_md5 "$TMP_APP"`

	if test "$MD5_OLD" = "$MD5_NEW"; then
		echo "no change"
		_rm "$TMP_APP" >/dev/null
	else
		echo "update"
		_mv "$TMP_APP" "$MAPP"
		_chmod 755 "$MAPP"
	fi

	test -z "$2" && exit 0
}

