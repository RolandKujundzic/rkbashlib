#!/bin/bash

#--
# Return $RKBASH_DIR/$1 create directory if missing.
# 
# @param log file name
# @return log file path
#--
function _log_file {
	_mkdir "$RKBASH_DIR"
	echo -n "$RKBASH_DIR/$1"
}
	
