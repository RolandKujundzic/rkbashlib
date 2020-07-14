#!/bin/bash

#--
# Create apigen documentation for php project in docs/apigen.
#
# @param source directory (optional, default = src)
# @param doc directory (optional, default = docs/apigen)
# @global CURR
#--
function _apigen_doc {
	local doc_dir prj bin src_dir
  doc_dir=./docs/apigen
	prj="docs/.apigen"
	bin="$prj/vendor/apigen/apigen/bin/apigen"
	src_dir=./src

	_mkdir "$doc_dir"
	_mkdir "$prj"
	_require_program composer

	if ! test -f "$prj/composer.json"; then
		_cd "$prj"
		_composer_json "rklib/rkphplib_doc_apigen"
		composer require "apigen/apigen:dev-master"
		composer require "roave/better-reflection:dev-master#c87d856"
		_cd "$CURR"
	fi

	if ! test -s "$bin"; then
		_cd "$prj"
		composer update
		_cd "$CURR"
	fi

	test -n "$1" && src_dir="$1"
	test -n "$2" && doc_dir="$2"

	_require_dir "$src_dir"

	if test -d "$doc_dir"; then
		_confirm "Remove existing documentation directory [$doc_dir] ?" 1
		if test "$CONFIRM" = "y"; then
			_rm "$doc_dir"
		fi
	fi

	echo "Create apigen documentation"
	echo "$bin generate '$src_dir' --destination '$doc_dir'"
	$bin generate "$src_dir" --destination "$doc_dir"
}

