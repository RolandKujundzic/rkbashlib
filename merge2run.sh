#!/bin/bash

SCRIPT_NAME=`realpath "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_NAME"`

. "$SCRIPT_DIR/src/abort.sh"
. "$SCRIPT_DIR/src/syntax.sh"

APP=$0

if test -z "$1"; then
	_syntax "[func1 func2 ... main]"
fi

if test -f "run.sh"; then
	_abort "run.sh already exists"
fi

echo -e "\nCreate run.sh"

echo -e "#!/bin/bash\nMERGE2RUN=\"$1\"\n" > run.sh

for a in $1
do
	FUNC="$SCRIPT_DIR/src/$a.sh"

	if test -f "sh/run/$a.sh"; then
		FUNC="sh/run/$a.sh"
	fi

	echo "use function _$a ($FUNC)"
	tail -n +2 "$FUNC" >> run.sh
done

chmod 755 run.sh

echo -e "done.\n\n"
