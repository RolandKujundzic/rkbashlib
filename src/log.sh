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
# @param name (if set use $RKSCRIPT_DIR/$name/$NAME_COUNT.nfo)
# @export LOG_NO_ECHO LOG_COUNT[$2] LOG_FILE[$2] LOG_CMD[$2]
#------------------------------------------------------------------------------
function _log {
	test -z "$LOG_NO_ECHO" && echo -n "$1"
	
	if test -z "$2"; then
		test -z "$LOG_NO_ECHO" && echo
		return
	fi

	# assume $1 is shell command
	LOG_COUNT[$2]=$((LOG_COUNT[$2] + 1))
	LOG_FILE[$2]="$RKSCRIPT_DIR/$2/${LOG_COUNT[$2]}.nfo"
	LOG_CMD[$2]=">> '${LOG_FILE[$2]}' 2>&1"

	if ! test -d "$RKSCRIPT_DIR/$2"; then
		mkdir -p "$RKSCRIPT_DIR/$2"
		if ! test -z "$SUDO_USER"; then
			chown -R $SUDO_USER.$SUDO_USER "$RKSCRIPT_DIR" || _abort "chown -R $SUDO_USER.$SUDO_USER '$RKSCRIPT_DIR'"
		elif test "$UID" = "0"; then
			chmod -R 777 "$RKSCRIPT_DIR" || _abort "chmod -R 777 '$RKSCRIPT_DIR'"
		fi
	fi

	local NOW=`date +'%d.%m.%Y %H:%M:%S'`
	echo -e "# _$2: $NOW\n# $PWD\n# $1 ${LOG_CMD[$2]}\n" > "${LOG_FILE[$2]}"

	if ! test -z "$SUDO_USER"; then
		chown $SUDO_USER.$SUDO_USER "${LOG_FILE[$2]}" || _abort "chown $SUDO_USER.$SUDO_USER '${LOG_FILE[$2]}'"
	elif test "$UID" = "0"; then
		chmod 666 "${LOG_FILE[$2]}" || _abort "chmod 666 '${LOG_FILE[$2]}'"
	fi

	test -z "$LOG_NO_ECHO" && echo " ${LOG_CMD[$2]}"
}

