#!/bin/bash

#-------------------------------------------------------------------------------
# Install or update npm packages. Create package.json and README.md if missing.
#
# @export NPM_PACKAGE="pkg1 .. pkgN"
# @export NPM_PACKAGE_DEV="pkg1 ... pkgN"
# @require _npm_module
#-------------------------------------------------------------------------------
function _package_json {

	if ! test -f package.json; then
		echo "create: package.json"
		echo '{ "name": "ToDo", "version": "0.1.0", "title": "ToDo", "description": "ToDo", "repository": {} }' > package.json
	fi

	if ! test -f README.md; then
		echo "create: README.md - adjust content"
		echo "ToDo" > README.md
	fi

	local RUN_INSTALL=
	local HAS_PKG=

	for a in $NPM_PACKAGE $NPM_PACKAGE_DEV; do
		HAS_PKG=`grep $a package.json`
		if ! test -z "$HAS_PKG"; then
			RUN_INSTALL=1
		fi
	done

	if ! test -z "$RUN_INSTALL"; then
		echo "run: npm install"
		npm install
	fi

	for a in $NPM_PACKAGE; do
		_npm_module $a --save
	done

	for a in $NPM_PACKAGE_DEV; do
		_npm_module $a --save-dev
	done
}

