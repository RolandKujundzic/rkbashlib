#!/bin/bash

declare -Ai LOG_COUNT  # define hash (associative array) of integer
declare -A LOG_FILE  # define hash
declare -A LOG_CMD  # define hash
LOG_NO_ECHO=

#------------------------------------------------------------------------------
# Pring log message. If second parameter is set assume command logging.
# Set LOG_NO_ECHO=1 to disable echo output.
#
# @param message
# @export LOG_NO_ECHO LOG_COUNT[$2] LOG_FILE[$2] LOG_CMD[$2]
# @param name (if set use .rkscript/$name/$NAME_COUNT.nfo)
# @require _mkdir
#------------------------------------------------------------------------------
function _log {
	test -z "$LOG_NO_ECHO" || echo -n "$1"
	
	if test -z "$2"; then
		test -z "$LOG_NO_ECHO" || echo
		return
	fi

	# assume $1 is shell command
	LOG_COUNT[$2]=$((LOG_COUNT[$2] + 1))
	LOG_FILE[$2]=".rkscript/$2/${LOG_COUNT[$2]}.nfo"
	LOG_CMD[$2]=">> '${LOG_FILE[$2]}' 2>&1"

	_mkdir ".rkscript/$2"

  local NOW=`date +'%d.%m.%Y %H:%M:%S'`
	echo -e "# _$2: $NOW\n# $PWD\n# $1 ${LOG_CMD[$2]}\n" > "${LOG_FILE[$2]}"

	test -z "$LOG_NO_ECHO" || echo " LOG_CMD[$2]"
}

