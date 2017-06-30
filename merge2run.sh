#!/bin/bash
#
# Copyright (c) 2017 Roland Kujundzic <roland@kujundzic.de>
#

SCRIPT_NAME="$0"

command -v realpath > /dev/null 2>&1 && SCRIPT_NAME=`realpath "$0"`

SCRIPT_DIR=`dirname "$SCRIPT_NAME"`

. "$SCRIPT_DIR/src/abort.sh"
. "$SCRIPT_DIR/src/syntax.sh"
. "$SCRIPT_DIR/src/confirm.sh"
. "$SCRIPT_DIR/src/rm.sh"

APP=$0
OUT=run.sh

if test -z "$1"; then
	if test -f sh/run/merge2run.sh; then
		. sh/run/merge2run.sh
	else
		_syntax "[func1 func2 ... main]"
	fi
else
	if test -f sh/run/merge2$1; then
		. sh/run/merge2$1
		OUT=$1
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

echo -e "#!/bin/bash\nMERGE2RUN=\"$MERGE2RUN\"\n" > $OUT

for a in $MERGE2RUN
do
	FUNC="$SCRIPT_DIR/src/$a.sh"

	if test -f "sh/run/$a.sh"; then
		FUNC="sh/run/$a.sh"
	fi

	echo "use function _$a ($FUNC)"
	tail -n +2 "$FUNC" >> $OUT
done

chmod 755 $OUT

echo -e "done.\n\n"
