#!/bin/bash

#--
# Create phpdocumentor documentation for php project in docs/phpdocumentor.
#
# @param source directory (optional, default = src)
# @param doc directory (optional, default = docs/phpdocumentor)
#--
function _phpdocumentor {
  local DOC_DIR=./docs/phpdocumentor
	local PRJ="docs/.phpdocumentor"
	local BIN="$PRJ/vendor/phpdocumentor/phpdocumentor/bin/phpdoc"
	local SRC_DIR=./src

	_mkdir "$DOC_DIR"
	_mkdir "$PRJ"
	_require_program composer

	local CURR="$PWD"

	if ! test -f "$PRJ/composer.json"; then
		_cd "$PRJ"
		_composer_json "rklib/rkphplib_doc_phpdocumentor"
		composer require "phpdocumentor/phpdocumentor:dev-master"
		_cd "$CURR"
	fi

	if ! test -s "$BIN"; then
		_cd "$PRJ"
		composer update
		_cd "$CURR"
	fi

	test -n "$1" && SRC_DIR="$1"
	test -n "$2" && DOC_DIR="$2"

	_require_dir "$SRC_DIR"

	if test -d "$DOC_DIR"; then
		_confirm "Remove existing documentation directory [$DOC_DIR] ?" 1
		if test "$CONFIRM" = "y"; then
			_rm "$DOC_DIR"
		fi
	fi

	echo "Create phpdocumentor documentation"
	echo "$BIN run -d '$SRC_DIR' -t '$DOC_DIR'"
	$BIN run -d "$SRC_DIR" -t "$DOC_DIR"
}
