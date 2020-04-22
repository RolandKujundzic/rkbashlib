#!/bin/bash

#--
# @deprecated use _append_file
# @param target file
# @param source file
#--
function _append {
	_msg "DEPRECATED: use _append_file"
	_append_file "$1" "$2"
}

