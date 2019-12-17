#!/bin/bash

#--
# Return random string length $1
# @param string length (default = 8)
# @require _require_program
#--
function _random_string {
	_require_program sha256sum
	_require_program base64
	_require_program head

	local LEN=${1:-8}
	date +%s | sha256sum | base64 | head -c $LEN
}

