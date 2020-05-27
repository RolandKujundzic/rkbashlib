#!/bin/bash

#--
# Merge "$APP"_ (or ../`basename "$APP"`) directory into $APP (concat *.inc.sh).
# Use 0_header.inc.sh, function.inc.sh, ... Z0_configuration.inc.sh, Z1_setup.inc.sh, Z_main.inc.sh.
# Set RKS_HEADER=0 to avoid rkbash.lib.sh loading. Use --static to include rkbash.lib.sh functions.
# 
# @example test.sh, test.sh_/ and test.sh_/*.inc.sh
# @example test.sh/, test.sh/test.sh and test.sh/*.inc.sh
#
# @global APP RKS_HEADER
# @param split dir (optional if $APP is used)
# @param output file (optional if $APP is used)
# shellcheck disable=SC2119,SC2086,SC2034,SC2120
#--
function _merge_sh {
	local a my_app mb_app sh_dir rkbash_inc tmp_app md5_new md5_old inc_sh scheck
	my_app="${1:-$APP}"
	sh_dir="${my_app}_"

	if ! test -z "$2"; then
		my_app="$2"
		sh_dir="$1"
	else
		_require_file "$my_app"
		mb_app=$(basename "$my_app")
		test -d "$sh_dir" || { test -d "$mb_app" && sh_dir="$mb_app"; }
	fi

	test "${ARG[static]}" = "1" && rkbash_inc=$(_merge_static "$sh_dir")

	_require_dir "$sh_dir"

	tmp_app="$sh_dir"'_'
	test -s "$my_app" && md5_old=$(_md5 "$my_app")
	echo -n "merge $sh_dir into $my_app ... "

	inc_sh=$(find "$sh_dir" -name '*.inc.sh' 2>/dev/null | sort)
	scheck=$(grep -E '^# shellcheck disable=' $inc_sh | sed -E 's/.+ disable=(.+)$/\1/g' | tr ',' ' ' | xargs -n1 | sort -u | xargs | tr ' ' ',')
	test -z "$scheck" || RKS_HEADER_SCHECK="shellcheck disable=SC1091,$scheck"

	if test -z "$rkbash_inc"; then
		_rks_header "$tmp_app" 1
	else
		_rks_header "$tmp_app"
		echo "$rkbash_inc" >> "$tmp_app"
	fi

	for a in $inc_sh; do
		tail -n+2 "$a" | grep -E -v '^# shellcheck disable=' >> "$tmp_app"
	done

	_add_abort_linenum "$tmp_app"

	md5_new=$(_md5 "$tmp_app")
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


#--
# Return include code
# @param script source dir
# shellcheck disable=SC2153,SC2086
#--
function _merge_static {
	local a rks_inc inc_sh
	inc_sh=$(find "$1" -name '*.inc.sh' 2>/dev/null | sort)

	for a in $inc_sh; do
		_rkbash_inc "$a"
		rks_inc="$rks_inc $RKBASH_INC"
	done

	for a in $(_sort $rks_inc); do
		tail -n +2 "$RKBASH_SRC/${a:1}.sh" | grep -E -v '^\s*#'
	done
}

