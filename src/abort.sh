#!/bin/bash

#------------------------------------------------------------------------------
# Abort with error message.
#
# @exit
# @global APP
# @param abort message
#------------------------------------------------------------------------------
function _abort {
	echo -e "\nABORT: $1\n\n" 1>&2
	# make shure APP dies even if _abort is called from subprocess
  kill $(ps aux | grep "$APP" | awk '{print $2}')
	exit 1
}

