#!/bin/bash
#
# Copyright (c) 2017 Roland Kujundzic <roland@kujundzic.de>
#

SCRIPT_NAME="$0"
command -v realpath > /dev/null 2>&1 && SCRIPT_NAME=`realpath "$0"`

SCRIPT_SRC=`dirname "$SCRIPT_NAME"`"/src"
LOAD_FUNC="abort msg osx syntax confirm require_global required_rkscript scan_rkscript_src cache mkdir cd rm"

for a in $LOAD_FUNC; do
	. "$SCRIPT_SRC/$a.sh"
done

test -z "$RKSCRIPT_PATH" && RKSCRIPT_PATH=`dirname "$SCRIPT_NAME"`

APP=$0
OUT=run.sh
export APP_PID="$APP_PID $$"

echo

if ! test -z "$MERGE2RUN_OUTPUT"; then
	OUT="$MERGE2RUN_OUTPUT"
	echo "OUT=$OUT"
fi

if test -z "$1"; then
	if test -f sh/run/merge2run.sh; then
		echo "load sh/run/merge2run.sh"
		. sh/run/merge2run.sh
	else
		_syntax "[func1 func2 ... main]"
	fi
else
	if test -f "sh/run/merge2$1"; then
		echo "load sh/run/merge2$1" 
		. sh/run/merge2$1

		echo "OUT=$1"
		OUT=$1

		if ! test -z "$SCAN_INCLUDE"; then
			_scan_rkscript_src
			INCLUDE=

			for a in $MERGE2RUN; do
				_required_rkscript "sh/run/$a"".sh" 1
				INCLUDE="$REQUIRED_RKSCRIPT $INCLUDE"
			done

			# OSX workaround: use [sed -e 's/ /\'$'\n/g'] instead of [sed -e "s/ /\n/g"]
			INCLUDE=`echo "$INCLUDE" | sed -e 's/ /\'$'\n/g' | sed -e "s/^_//g" | xargs`
			MERGE2RUN="$INCLUDE $MERGE2RUN"
		fi
	else
		MERGE2RUN="$1"
	fi
fi

if test -f "$OUT"; then
	_confirm "Remove existing $OUT?" 1

	if test $CONFIRM = "y"; then
		_rm $OUT
	else
		_abort "$OUT already exists"
	fi
fi

# make MERGE2RUN\ entries unique - but main must stay at the end!
M2R_LIST=( $MERGE2RUN )
MERGE2RUN=`echo "$MERGE2RUN" | sed -e 's/ /\n/g' | sort -u - | tr '\n' ' '`

# put main function last
MAIN_FUNC=${M2R_LIST[-1]}
MERGE2RUN=`echo "$MERGE2RUN" | sed -e "s/ $MAIN_FUNC//"`" $MAIN_FUNC"

# put copyright first
test "${M2R_LIST[0]}" = "copyright" && MERGE2RUN="copyright "`echo "$MERGE2RUN" | sed -e "s/ copyright//"`

echo "Create $OUT ($MERGE2RUN)"

echo -e "#!/bin/bash\nMERGE2RUN=\"$MERGE2RUN\"\n" > $OUT

for a in $MERGE2RUN
do
	FUNC="$SCRIPT_SRC/$a.sh"

	if test -f "sh/run/$a.sh"; then
		FUNC="sh/run/$a.sh"
	fi

	tail -n +2 "$FUNC" >> $OUT
done

chmod 755 $OUT

echo -e "done.\n\n"
