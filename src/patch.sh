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
# @require _abort _msg _require_program _require_global _require_dir _orig
#--
function _patch {
	if test -s "$1"; then
		PATCH_LIST=`basename "$1" | sed -E 's/\.patch$//'`
		PATCH_SOURCE_DIR=`dirname "$1"`
		if test -z "$PATCH_DIR"; then
			PATCH_DIR=`echo "$PATCH_SOURCE_DIR" | grep 'conf/' | sed -E 's/^.*conf\///'`
			test -d "/$PATCH_DIR" && PATCH_DIR="/$PATCH_DIR"
		fi
	elif test -f "$1/patch.sh"; then
		PATCH_SOURCE_DIR=`dirname "$1"`
		. "$1/patch.sh" || _abort ". $1/patch.sh"
	elif ! test -z "$1" && test -d "$1"; then
		PATCH_SOURCE_DIR="$1"
	fi

	_require_program patch
	_require_dir "$PATCH_DIR"
	_require_dir "$PATCH_SOURCE_DIR"
	_require_global PATCH_LIST

	local a; local TARGET;
	for a in $PATCH_LIST; do
		TARGET=`find $PATCH_DIR -name "$a"`

		if test -f "$PATCH_SOURCE_DIR/$a.patch" && test -f "$TARGET"; then
			CONFIRM="y"

			_orig "$TARGET" || _confirm "$TARGET.orig already exists patch anyway?"

			if test "$CONFIRM" = "y"; then
				_msg "patch '$TARGET' '$PATCH_SOURCE_DIR/$a.patch'"
				patch "$TARGET" "$PATCH_SOURCE_DIR/$a.patch" || _abort "patch '$a.patch' failed"
			fi
		else
			_msg "skip $a.patch - missing either $PATCH_SOURCE_DIR/$a.patch or $TARGET"
		fi
	done
}

