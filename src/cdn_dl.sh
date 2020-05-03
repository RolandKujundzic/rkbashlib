#!/bin/bash

#--
# Download source url to target path.
#
# @global DOCROOT if not empty and head.inc.html exists copy files here and append to head.inc.html
# @global CDN_DIR path prefix (if empty use ./)
#
# @param string source url
# @param string target path
# shellcheck disable=SC2046
#--
function _cdn_dl {
	local suffix target has_file
	suffix=$(echo "$2" | awk -F . '{print $NF}')
	target="$2"

	if test -z "$CDN_DIR"; then
		target="./$target"
	else
		target="$CDN_DIR/$target"
	fi

	_mkdir $(dirname "$target")
	_download "$1" "$target"
	_download "$1.map" "$target.map" 1

	if ! test -z "$DOCROOT"; then
		_cp "$target" "$DOCROOT/$2"

		if test -f "$target.map"; then
			_cp "$target.map" "$DOCROOT/$2.map"
		fi

		if test -f "$DOCROOT/head.inc.html"; then
			has_file=$(grep "=\"$2\"" "$DOCROOT/head.inc.html")

			if ! test -z "$has_file"; then
				echo "$2 is already in head.inc.html"
			elif test "$suffix" = "css" && test -f "$DOCROOT/$2"; then
				sed -e "s/<\/head>/<link rel=\"stylesheet\" href=\"$2\" \/>/g" > "$DOCROOT/head.inc.html"
			elif test "$suffix" = "js" && test -f "$DOCROOT/$2"; then
				sed -e "s/<\/head>/<script src=\"$2\"><\/script>/g" > "$DOCROOT/head.inc.html"
			fi
		fi
	fi
}

