#!/bin/bash

#------------------------------------------------------------------------------
# Create apigen documentation for php project in docs/apigen.
#
# @param source directory (optional, default = src)
# @param doc directory (optional, default = docs/apigen)
# @require _abort _require_program _require_dir _mkdir _cd _composer_json _confirm _rm
#------------------------------------------------------------------------------
function _apigen_doc {
  local DOC_DIR=./docs/apigen
	local PRJ="docs/.apigen"
	local BIN="$PRJ/vendor/apigen/apigen/bin/apigen"
	local SRC_DIR=./src

	_mkdir "$DOC_DIR"
	_mkdir "$PRJ"
	_require_program composer

	local CURR="$PWD"

	if ! test -f "$PRJ/composer.json"; then
		_cd "$PRJ"
		_composer_json "rklib/rkphplib_doc_apigen"
		composer require "apigen/apigen:dev-master"
		composer require "roave/better-reflection:dev-master#c87d856"
		_cd "$CURR"
	fi

	if ! test -s "$BIN"; then
		_cd "$PRJ"
		composer update
		_cd "$CURR"
	fi

	if ! test -z "$1"; then
		SRC_DIR="$1"
	fi

	if ! test -z "$2"; then
		DOC_DIR="$2"
	fi

	_require_dir "$SRC_DIR"

	if test -d "$DOC_DIR"; then
		_confirm "Remove existing documentation directory [$DOC_DIR] ?" 1
		if test "$CONFIRM" = "y"; then
			_rm "$DOC_DIR"
		fi
	fi

	echo "Create apigen documentation"
	echo "$BIN generate '$SRC_DIR' --destination '$DOC_DIR'"
	$BIN generate "$SRC_DIR" --destination "$DOC_DIR"
}

