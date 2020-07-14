#!/bin/bash

#--
# Install or update npm packages. Create package.json and README.md if missing.
# Apply patches if patch/patch.sh exists.
#
# @param upgrade (default = empty = false)
# @global NPM_PACKAGE NPM_PACKAGE_GLOBAL NPM_PACKAGE_DEV (e.g. "pkg1 ... pkgN")
# shellcheck disable=SC2086
#--
function _package_json {
	local a

	if ! test -f package.json; then
		echo "create: package.json"
		echo '{ "name": "ToDo", "version": "0.1.0", "title": "ToDo", "description": "ToDo", "repository": {} }' > package.json
	fi

	if ! test -f README.md; then
		echo "create: README.md - adjust content"
		echo "ToDo" > README.md
	fi

	if test -n "$1"; then
		echo "upgrade package.json"
		_npm_module npm-check-updates -g
		npm-check-updates -u
	fi

	for a in $NPM_PACKAGE_GLOBAL; do
		_npm_module "$a" -g
	done

	local run_install
	for a in $NPM_PACKAGE $NPM_PACKAGE_DEV; do
		if ! grep "$a" package.json >/dev/null; then
			run_install=1
		fi
	done

	if test -n "$run_install"; then
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
		_cd patch
		./patch.sh
		_cd ..
	fi
}

