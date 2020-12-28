#!/bin/bash

#--
# Abort if file and checksum are set and mismatch
# @param file
# @param sha256 checksum
#--
function _sha256 {
	[[ ! -f "$1" || -z "$2" ]] && return
	local checksum

	checksum=$(sha256sum "$1" | awk '{print $1}')
	test "$checksum" = "$2" || _abort "invalid SH256 checksum\n$1\n$checksum != $2"
}

