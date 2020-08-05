#!/bin/bash

#--
# Patch either PATCH_LIST and PATCH_DIR are set or $1/patch.sh exists.
# If $1/patch.sh exists it must export PATCH_LIST and PATCH_DIR (set PATCH_SOURCE_DIR = dirname $1).
# If $1 is file assume PATCH_SOURCE_DIR=dirname $1, PATCH_LIST=basename $1 and PATCH_DIR is either
# absoulte or relative path after 'conf/'.
# Apply patch if target file and patch file exist.
#
# @global PATCH_SOURCE_DIR PATCH_LIST PATCH_DIR
# @param patch file directory or patch source file (optional)
# shellcheck disable=SC1090
#--
function _patch {
	if [[ -n "$1" && -d "$1" ]]; then
		PATCH_SOURCE_DIR="$1"
	elif test -s "$1"; then
		PATCH_LIST=$(basename "$1" | sed -E 's/\.patch$//')
		PATCH_SOURCE_DIR=$(dirname "$1")
		if test -z "$PATCH_DIR"; then
			PATCH_DIR=$(echo "$PATCH_SOURCE_DIR" | grep 'conf/' | sed -E 's/^.*conf\///')
			test -d "/$PATCH_DIR" && PATCH_DIR="/$PATCH_DIR"
		fi
	elif test -f "$1/patch.sh"; then
		PATCH_SOURCE_DIR=$(dirname "$1")
		_include "$1/patch.sh"
	fi

	_require_program patch
	_require_dir "$PATCH_DIR"
	_require_dir "$PATCH_SOURCE_DIR"
	_require_global PATCH_LIST

	local a target
	for a in $PATCH_LIST; do
		test -f "$PATCH_DIR/$a" && target="$PATCH_DIR/$a" || target=$(find "$PATCH_DIR" -name "$a")

		if test -f "$PATCH_SOURCE_DIR/$a.patch" && test -f "$target"; then
			CONFIRM="y"
			_orig "$target" >/dev/null || _confirm "$target.orig already exists patch anyway?"
			if test "$CONFIRM" = "y"; then
				_msg "patch '$target' '$PATCH_SOURCE_DIR/$a.patch'"
				patch "$target" "$PATCH_SOURCE_DIR/$a.patch" || _abort "patch '$a.patch' failed"
			fi
		else
			_msg "skip $a.patch - missing either $PATCH_SOURCE_DIR/$a.patch or [$target]"
		fi
	done

	PATCH_DIR=
}

