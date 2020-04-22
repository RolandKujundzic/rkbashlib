#!/bin/bash

#--
# Download source url to target path.
#
# @global DOCROOT if not empty and head.inc.html exists copy files here and append to 
# head.inc.html
#
# @global CDN_DIR path prefix (if empty use ./)
#
# @param string source url
# @param string target path
#--
function _cdn_dl {
	local SUFFIX=`echo "$2" | awk -F . '{print $NF}'`
	local TARGET="$2"

	if test -z "$CDN_DIR"; then
		TARGET="./$TARGET"
	else
		TARGET="$CDN_DIR/$TARGET"
	fi

	_mkdir `dirname "$TARGET"`
	_download "$1" "$TARGET"
	_download "$1.map" "$TARGET.map" 1

	if ! test -z "$DOCROOT"; then
		_cp "$TARGET" "$DOCROOT/$2"

		if test -f "$TARGET.map"; then
			_cp "$TARGET.map" "$DOCROOT/$2.map"
		fi

		if test -f "$DOCROOT/head.inc.html"; then
			local HAS_FILE=`grep "=\"$2\"" "$DOCROOT/head.inc.html"`

			if ! test -z "$HAS_FILE"; then
				echo "$2 is already in head.inc.html"
			elif test "$SUFFIX" = "css" && test -f "$DOCROOT/$2"; then
				sed -e "s/<\/head>/<link rel=\"stylesheet\" href=\"$2\" \/>/g" > "$DOCROOT/head.inc.html"
			elif test "$SUFFIX" = "js" && test -f "$DOCROOT/$2"; then
				sed -e "s/<\/head>/<script src=\"$2\"><\/script>/g" > "$DOCROOT/head.inc.html"
			fi
		fi
	fi
}

