#!/bin/bash
#
# Copyright (c) 2017-2020 Roland Kujundzic <roland@kujundzic.de>
#


#--
# Load necessary src/* functions.
# @export RKSCRIPT_PATH
#--
function load_functions {
	if test -z "$RKSCRIPT_PATH"; then
		RKSCRIPT_PATH=`realpath "$APP" | xargs dirname`
	fi

	local load_func="abort msg osx syntax sort confirm log sudo require_global rkscript_inc cache mkdir cd cp rm add_abort_linenum"
	local a

	for a in $load_func; do
		. "$RKSCRIPT_PATH/src/$a.sh"
	done
}


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

	if test -f "$OUT"; then
		_confirm "Remove existing $OUT?" 1
		test $CONFIRM = "y" && _rm "$OUT" || _abort "$OUT already exists"
	fi
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

	local copyright=`date +"%Y"`
	test -f ".gitignore" && copyright=`git log --diff-filter=A -- .gitignore | grep 'Date:' | sed -E 's/.+ ([0-9]+) \+[0-9]+/\1/'`" - $copyright"

	echo -e "#!/bin/bash\n#\n# Copyright (c) $copyright Roland Kujundzic <roland@kujundzic.de>\n#" > "$OUT"

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

load_functions
merge_list $@
include_list
join_include

echo -e "done.\n"
