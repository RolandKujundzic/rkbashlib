#!/bin/bash
#
# Copyright (c) 2017-2020 Roland Kujundzic <roland@kujundzic.de>
#


#--
# Compute merge list.
# 
# @export OUT MERGE_SH
# @param $@
#--
function merge_list {
	OUT="run.sh"
	MERGE_SH=

	test -s "sh/run/merge2$1" && OUT="$1"

	if [[ "$#" -gt 0 && -s "$1" ]]; then
		MERGE_SH="$@"
	elif test -s "sh/run/merge2$OUT"; then
		echo "load sh/run/merge2$OUT"
		. "sh/run/merge2$OUT"

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
#--
function include_list {
	echo "Scan for rkscript functions"
	INCLUDE=

	local a
	for a in $MERGE_SH; do
		echo -n "in $a ... "
		_rkscript_inc "$a" #>/dev/null
		echo "found $RKSCRIPT_INC_NUM"
		INCLUDE="$RKSCRIPT_INC $INCLUDE"
	done

	INCLUDE=`_sort $INCLUDE`
}


#--
# Join INCLUDE and MERGE_SH snipplets into OUT.
#
# @global RKSCRIPT_PATH INCLUDE MERGE_SH OUT
#--
function join_include {
	echo -e "Include: $INCLUDE\nCreate $OUT"

	_rks_header "$OUT"

	local a
	for a in $INCLUDE; do
		tail -n +2 "$RKSCRIPT_PATH/src/${a:1}.sh" | grep -E -v '^\s*#' >> "$OUT"
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
CWD="$PWD"
APP_DESC="Merge shell code snipplets"
export APP_PID="$APP_PID $$"

echo -e "\n$APP_DESC"

# Load necessary src/* functions - don't put in function (declare -A will be lost)
if test -z "$RKSCRIPT_PATH"; then
	RKSCRIPT_PATH=`realpath "$APP" | xargs dirname`
fi

load_func="abort add_abort_linenum chmod confirm cp find log md5
	merge_sh mkdir msg mv parse_arg require_dir require_file require_owner 
	require_priv require_program rkscript_inc rks_header rm rsync sort sudo 
	syntax"

for a in $load_func; do
	source "$RKSCRIPT_PATH/src/$a.sh"
done

_parse_arg $@

if [[ ! -z "${ARG[scan]}" && -s "${ARG[scan]}" ]]; then
	_rkscript_inc "${ARG[scan]}" #>/dev/null
	echo "found $RKSCRIPT_INC_NUM: $RKSCRIPT_INC"
elif [[ ! -z "${ARG[self_update]}" && -f "${ARG[self_update]}" && -d "${ARG[self_update]}_" ]]; then
	echo "_merge_sh '${ARG[self_update]}_' '${ARG[self_update]}'"
	_merge_sh "${ARG[self_update]}_" "${ARG[self_update]}" 
else
	merge_list $@
	include_list
	join_include
fi

echo -e "done.\n"
