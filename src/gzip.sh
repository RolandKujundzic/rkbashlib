#!/bin/bash

#--
# Gzip $1
# @param file path
#--
function _gzip {
	_require_file "$1"
	_msg "gzip $1"
	_require_program gzip
	gzip "$1" || _abort "gzip '$1'"
	_require_file "$1.gz"
}

