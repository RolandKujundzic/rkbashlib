#!/bin/bash
#
# Copyright (c) 2017 Roland Kujundzic <roland@kujundzic.de>
#

APP=$0
CWD="$PWD"
APP_DESC="merge shell code snipplets"
export APP_PID="$APP_PID $$"

if test -z "$RKSCRIPT_PATH"; then
	RKSCRIPT_PATH=`realpath "$0" | xargs dirname`
fi

LOAD_FUNC="abort msg osx syntax sort confirm log sudo require_global rkscript_inc cache mkdir cd cp rm add_abort_linenum"
for a in $LOAD_FUNC; do
	. "$RKSCRIPT_PATH/src/$a.sh"
done

OUT="run.sh"
test -s "sh/run/merge2$1" && OUT="$1"

if test -s "sh/run/merge2$OUT"; then
	echo "load sh/run/merge2$OUT"
	. "sh/run/merge2$OUT"

	MERGE_SH=
	for a in $MERGE2RUN; do
		MERGE_SH="$MERGE_SH sh/run/$a.sh"
	done
else
	MERGE_SH="$@"
fi

test -z "$MERGE_SH" && _syntax "path/func1.sh path/func2.sh ... path/main.sh"

echo "Scan for rkscript functions"
INCLUDE=
for a in $MERGE_SH; do
	echo -n "in $a ... "
	_rkscript_inc "$a" #>/dev/null
	echo "found $RKSCRIPT_INC_NUM"
	INCLUDE="$RKSCRIPT_INC $INCLUDE"
done

INCLUDE=`_sort $INCLUDE`

if test -f "$OUT"; then
	_confirm "Remove existing $OUT?" 1
	test $CONFIRM = "y" && _rm "$OUT" || _abort "$OUT already exists"
fi

echo -e "Include: $INCLUDE\nCreate $OUT"
test -z "$MERGE2RUN_OUTPUT" || OUT="$MERGE2RUN_OUTPUT"

echo -e "#!/bin/bash\n" > "$OUT"
for a in $INCLUDE; do
	tail -n +2 "$RKSCRIPT_PATH/src/${a:1}.sh" | grep -E -v '^\s*#' >> "$OUT"
done

for a in $MERGE_SH; do
	tail -n +2 "$a" >> "$OUT"
done

_add_abort_linenum "$OUT"

chmod 755 "$OUT"

echo -e "done.\n"

