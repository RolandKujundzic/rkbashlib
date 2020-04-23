#!/bin/bash

#--
# Merge "$APP"_ (or ../`basename "$APP"`) directory into $APP (concat *.inc.sh).
# Use 0_header.inc.sh, function.inc.sh, ... Z0_configuration.inc.sh, Z1_setup.inc.sh, Z_main.inc.sh.
# Set RKS_HEADER=0 to avoid rkscript.sh loading.
# 
# @example test.sh, test.sh_/ and test.sh_/*.inc.sh
# @example test.sh/, test.sh/test.sh and test.sh/*.inc.sh
#
# @global APP RKS_HEADER
# @param split dir (optional if $APP is used)
# @param output file (optional if $APP is used)
#--
function _merge_sh {
	local my_app="${1:-$APP}"
	local sh_dir="${my_app}_"

	if ! test -z "$2"; then
		my_app="$2"
		sh_dir="$1"
	else
		_require_file "$my_app"
		test -d "$sh_dir" || { test -d `basename $my_app` && sh_dir=`basename $my_app`; }
	fi

	_require_dir "$sh_dir"

	local tmp_app="$sh_dir"'_'
	local md5_old=
	test -s "$my_app" && md5_old=`_md5 "$my_app"`
	echo -n "merge $sh_dir into $my_app ... "

	_rks_header "$tmp_app" 1

	local inc_sh=`ls "$sh_dir"/*.inc.sh "$sh_dir"/*/*.inc.sh "$sh_dir"/*/*/*.inc.sh 2>/dev/null | sort`
	local a
	for a in $inc_sh; do
		tail -n+2 "$a" >> "$tmp_app"
	done

	_add_abort_linenum "$tmp_app"

	local md5_new=`_md5 "$tmp_app"`

	if test "$md5_old" = "$md5_new"; then
		echo "no change"
		_rm "$tmp_app" >/dev/null
	else
		echo "update"
		_mv "$tmp_app" "$my_app"
		_chmod 755 "$my_app"
	fi

	test -z "$2" && exit 0
}

