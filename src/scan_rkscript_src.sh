#!/bin/bash

#------------------------------------------------------------------------------
# Scan $RKSCRIPT_PATH/src/* directory.
#
# @export RKSCRIPT_FUNCTIONS 
# @global RKSCRIPT_PATH
# @require _require_global _cd
#------------------------------------------------------------------------------
function _scan_rkscript_src {
	RKSCRIPT_FUNCTIONS=

	_require_global RKSCRIPT_PATH

	local CURR=$PWD
	_cd $RKSCRIPT_PATH/src

	local F=
	local a=; for a in *.sh; do
		# negative length doesn't work in OSX bash replace ${a::-3} with ${a:0:${#a}-3}
		F="_"${a:0:${#a}-3}
		RKSCRIPT_FUNCTIONS="$F $RKSCRIPT_FUNCTIONS"
	done

	_cd $CURR
}

