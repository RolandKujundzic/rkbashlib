#!/bin/bash

#------------------------------------------------------------------------------
# Create apigen documentation for php project.
#
# @param source directory (optional, default = src)
# @param doc directory (optional, default = docs/api)
# @require composer, abort
#------------------------------------------------------------------------------
function _apigen_doc {

	if ! test -d vender/apigen/apigen; then
		_composer init
	fi

	local SRC_DIR=./src
	local DOC_DIR=./docs/api

	if ! test -z "$1"; then
		SRC_DIR="$1"
	fi

	if ! test -z "$2"; then
		DOC_DIR="$2"
	fi

	if ! test -d "$SRC_DIR"; then
		_abort "no such directory [$SRC_DIR]"
	fi

	if ! test -d "$DOC_DIR"; then
		_abort "remove existing documentation directory [$DOC_DIR] first"
	fi

	vendor/apigen/apigen/bin/apigen generate -s "$SRC_DIR" -d "$DOC_DIR"
}
