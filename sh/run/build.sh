#!/bin/bash

#------------------------------------------------------------------------------
function _build {
	local BIN="bin/$1"".sh"

	./merge2run.sh "copyright $2 $1"
	chmod 755 run.sh
	_cp run.sh "$BIN" md5
	rm run.sh
}


#------------------------------------------------------------------------------
# M A I N
#------------------------------------------------------------------------------

test -d bin || mkdir bin

_build rks-mysql_backup  "abort cd cp create_tgz rm mysql_dump mysql_backup"
_build rks-mysql_restore "abort confirm extract_tgz cd cp rm mkdir mv mysql_load mysql_restore mysql_conn"
_build rks-mysql_create  "abort syntax mysql_create_db mysql_split_dsn"
_build rks-lets_encrypt  "abort syntax run_as_root cd"
_build rks-apache2_site  "abort syntax run_as_root cd confirm"

