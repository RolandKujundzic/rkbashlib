#!/bin/bash

#------------------------------------------------------------------------------
# Execute command $1. Log command as .cmd/COUNT[.sh|.log|.err].
#
# @param command
# @param 2^n flag (2^0= print output, 2^1= execute .cmd/COUNT.sh)
# @export COMMAND_COUNT
# @require _abort _mkdir
#------------------------------------------------------------------------------
function _cmd {
	COMMAND_COUNT=$((COMMAND_COUNT + 1))

	_mkdir ".cmd"
	local CMD=".cmd/$COMMAND_COUNT"
	local FLAG=$(($2 + 0))

	echo -e "#!/bin/bash\n\ncd '$PWD'\n$1 > '$CMD.log' 2> '$CMD.err'\n" > "$CMD.sh"

	if test $((FLAG & 2)) = 2; then
		test $((FLAG & 1)) = 0 && echo -n "execute in $PWD: $CMD.sh ... "
		/bin/bash "$CMD.sh" || _abort "command failed"
  else
		test $((FLAG & 1)) = 0 && echo -n "execute in $PWD: $1 ... "
		$1 > "$CMD.log" 2> "$CMD.err" || _abort "command failed"
	fi
	
	if test $((FLAG & 1)) = 1; then
		cat "$CMD.log"
	else
		echo "ok"
	fi
}

