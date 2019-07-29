#!/bin/bash
#
# Copyright (c) 2017 Roland Kujundzic <roland@kujundzic.de>
#

SCRIPT_NAME="$0"
command -v realpath > /dev/null 2>&1 && SCRIPT_NAME=`realpath "$0"`

SCRIPT_SRC=`dirname "$SCRIPT_NAME"`"/src"

. "$SCRIPT_SRC/abort.sh"
. "$SCRIPT_SRC/syntax.sh"
. "$SCRIPT_SRC/confirm.sh"
. "$SCRIPT_SRC/require_global.sh"
. "$SCRIPT_SRC/required_rkscript.sh"
. "$SCRIPT_SRC/scan_rkscript_src.sh"
. "$SCRIPT_SRC/cd.sh"
. "$SCRIPT_SRC/rm.sh"

if test -z "$RKSCRIPT_PATH"; then
	RKSCRIPT_PATH=`dirname "$SCRIPT_NAME"`
fi

APP=$0
OUT=run.sh

if ! test -z "$MERGE2RUN_OUTPUT"; then
	OUT="$MERGE2RUN_OUTPUT"
fi

if test -z "$1"; then
	if test -f sh/run/merge2run.sh; then
		. sh/run/merge2run.sh
	else
		_syntax "[func1 func2 ... main]"
	fi
else
	if test -f "sh/run/merge2$1"; then
		. sh/run/merge2$1
		OUT=$1

		if ! test -z "$SCAN_INCLUDE"; then
			_scan_rkscript_src
			INCLUDE=

			for a in $MERGE2RUN; do
				_required_rkscript "sh/run/$a"".sh" 1
				echo "scan include sh/run/$a: $REQUIRED_RKSCRIPT"
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
	_confirm "Remove existing $OUT?"

	if test $CONFIRM = "y"; then
		_rm $OUT
	else
		_abort "$OUT already exists"
	fi
fi

echo -e "\nCreate $OUT"

# make MERGE2RUN\ entries unique - but main must stay at the end!
M2R_LIST=( $MERGE2RUN )
MERGE2RUN=`echo "$MERGE2RUN" | sed -e 's/ /\n/g' | sort -u - | tr '\n' ' '`

# put main function last
MAIN_FUNC=${M2R_LIST[-1]}
MERGE2RUN=`echo "$MERGE2RUN" | sed -e "s/ $MAIN_FUNC//"`" $MAIN_FUNC"

echo -e "#!/bin/bash\nMERGE2RUN=\"$MERGE2RUN\"\n" > $OUT

for a in $MERGE2RUN
do
	FUNC="$SCRIPT_SRC/$a.sh"

	if test -f "sh/run/$a.sh"; then
		FUNC="sh/run/$a.sh"
	fi

	echo "use function _$a ($FUNC)"
	tail -n +2 "$FUNC" >> $OUT
done

chmod 755 $OUT

echo -e "done.\n\n"
