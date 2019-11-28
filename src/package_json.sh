#!/bin/bash

#--
# Install or update npm packages. Create package.json and README.md if missing.
# Apply patches if patch/patch.sh exists.
#
# @param upgrade (default = empty = false)
# @global NPM_PACKAGE, NPM_PACKAGE_GLOBAL, NPM_PACKAGE_DEV (e.g. "pkg1 ... pkgN")
# @require _npm_module
#--
function _package_json {

	if ! test -f package.json; then
		echo "create: package.json"
		echo '{ "name": "ToDo", "version": "0.1.0", "title": "ToDo", "description": "ToDo", "repository": {} }' > package.json
	fi

	if ! test -f README.md; then
		echo "create: README.md - adjust content"
		echo "ToDo" > README.md
	fi

	if ! test -z "$1"; then
		echo "upgrade package.json"
		_npm_module npm-check-updates -g
		npm-check-updates -u
	fi

	local a=; for a in $NPM_PACKAGE_GLOBAL; do
		_npm_module $a -g
	done

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

	if test -f patch/patch.sh; then
		echo "Apply patches: patch/patch.sh"
		cd patch
		./patch.sh
		cd ..
	fi
}

