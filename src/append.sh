#!/bin/bash

#--
# @deprecated use _append_file
# @param target file
# @param source file
# @require _append_file _msg
#--
function _append {
	_msg "DEPRECATED: use _append_file"
	_append_file "$1" "$2"
}

