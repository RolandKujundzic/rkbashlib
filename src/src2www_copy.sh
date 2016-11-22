#!/bin/bash

#------------------------------------------------------------------------------
# Copy content from www_src to www.  and *.js files from src/javascript.
#
# @global SRC2WWW_FILES
# @global SRC2WWW_DIR
# @global SRC2WWW_RKJS_DIR
# @global SRC2WWW_RKJS_FILES
#------------------------------------------------------------------------------
function _src2www_copy {

	for a in $SRC2WWW_FILES $SRC2WWW_DIR; do
		cp -r www_src/$a www/
	done

	local JS_FILES="rkShoppingCart.min.js rk_lib.min.js tmpl.min.js jquery.min.js jquery.touchSwipe.min.js"

	for a in $SRC2WWW_RKJS_FILES; do
		cp $SRC2WWW_RKJS_DIR/$a www/js/
	done
}

