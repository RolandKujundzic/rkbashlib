#!/bin/bash

#------------------------------------------------------------------------------
function _build {
	local BIN="bin/$1"".sh"

	./merge2run.sh "$2 $1"
	chmod 755 run.sh
	_cp run.sh "$BIN"
}


#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

test -d bin || mkdir bin

_build bin/rks-mysql_backup "abort cd cp mysql_dump mysql_backup" 
