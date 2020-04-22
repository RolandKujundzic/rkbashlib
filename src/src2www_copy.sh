#!/bin/bash

#--
# Copy content from www_src to www.  and *.js files from src/javascript.
#
# @global SRC2WWW_FILES SRC2WWW_DIR SRC2WWW_RKJS_DIR SRC2WWW_RKJS_FILES
#--
function _src2www_copy {

	local a=; for a in $SRC2WWW_FILES $SRC2WWW_DIR; do
		cp -r www_src/$a www/
	done

	if ! test -z "$SRC2WWW_RKJS_FILES"; then
		_require_global "SRC2WWW_RKJS_DIR"
		for a in $SRC2WWW_RKJS_FILES; do
			cp $SRC2WWW_RKJS_DIR/$a www/js/
		done
	fi
}

