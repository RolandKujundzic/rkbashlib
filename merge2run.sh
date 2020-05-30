#!/bin/bash
#
# Copyright (c) 2017-2020 Roland Kujundzic <roland@kujundzic.de>
#


#--
# Compute merge list.
# 
# @export OUT MERGE_SH
# @param $@
# shellcheck disable=SC1090
#--
function merge_list {
	OUT="run.sh"
	MERGE_SH=

	if test -s "sh/run/merge2$1"; then
		OUT="$1"
		shift
	fi

	if [[ "$#" -gt 0 && -s "$1" ]]; then
		MERGE_SH="$*"
	elif test -s "sh/run/merge2$OUT"; then
		echo "load sh/run/merge2$OUT"
		source "sh/run/merge2$OUT"

		local a
		for a in $MERGE2RUN; do
			MERGE_SH="$MERGE_SH sh/run/$a.sh"
		done
	fi

	test -z "$MERGE_SH" && _syntax "path/func1.sh path/func2.sh ... path/main.sh"
	test -z "$MERGE2RUN_OUTPUT" || OUT="$MERGE2RUN_OUTPUT"
}


#--
# Compute include list.
#
# @export INCLUDE
# @global RKBASH_INC RKBASH_INC_NUM
# shellcheck disable=SC2086,SC2153
#--
function include_list {
	echo "Scan for rkbashlib functions"
	INCLUDE=

	local a
	for a in $MERGE_SH; do
		echo -n "in $a ... "
		_rkbash_inc "$a" #>/dev/null
		echo "found $RKBASH_INC_NUM"
		INCLUDE="$RKBASH_INC $INCLUDE"
	done

	INCLUDE=$(_sort $INCLUDE)
}


#--
# Join INCLUDE and MERGE_SH snipplets into OUT.
#
# @global RKBASH_SRC INCLUDE MERGE_SH OUT
# shellcheck disable=SC2034,SC2086
#--
function join_include {
	local a src_inc scheck
	echo -e "Include: $INCLUDE\nCreate $OUT"

	for a in $INCLUDE; do
		src_inc="$src_inc $RKBASH_SRC/${a:1}.sh"
	done

	scheck=$(grep -E '^# shellcheck disable=' $src_inc $MERGE_SH | \
		sed -E 's/.+ disable=(.+)$/\1/g' | tr ',' ' ' | xargs -n1 | sort -u | xargs | tr ' ' ',')
	test -z "$scheck" || RKS_HEADER_SCHECK="shellcheck disable=SC1091,$scheck"

	_rks_header "$OUT"

	for a in $src_inc; do
		tail -n +2 "$a" | grep -E -v '^\s*#' >> "$OUT"
	done

	for a in $MERGE_SH; do
		tail -n +2 "$a" >> "$OUT"
	done

	_add_abort_linenum "$OUT"

	chmod 755 "$OUT"
}


#--
# M A I N
#--

APP=$0
# shellcheck disable=SC2034
CWD="$PWD"
APP_DESC="Merge shell code snipplets"
export APP_PID="$APP_PID $$"

echo -e "\n$APP_DESC"

# Load necessary src/* functions - don't put in function (declare -A will be lost)
if test -z "$RKBASH_SRC"; then
	RKBASH_SRC="$(realpath "$APP" | xargs dirname)/src"
fi

load_func="abort add_abort_linenum chmod confirm cp find log md5
	merge_sh mkdir msg mv parse_arg require_dir require_file require_owner 
	require_priv require_program rkbash_inc rks_header rm rsync sort sudo 
	syntax"

for a in $load_func; do
	source "$RKBASH_SRC/$a.sh"
done

_parse_arg "$@"

if [[ ! -z "${ARG[scan]}" && -s "${ARG[scan]}" ]]; then
	_rkbash_inc "${ARG[scan]}" #>/dev/null
	echo "found $RKBASH_INC_NUM: $RKBASH_INC"
elif [[ ! -z "${ARG[self_update]}" && -f "${ARG[self_update]}" && -d "${ARG[self_update]}_" ]]; then
	echo "_merge_sh '${ARG[self_update]}_' '${ARG[self_update]}'"
	_merge_sh "${ARG[self_update]}_" "${ARG[self_update]}" 
else
	merge_list "$@"
	include_list
	join_include
fi

echo -e "done.\n"
